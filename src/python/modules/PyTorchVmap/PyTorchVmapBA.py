# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import numpy as np
import torch

from modules.PyTorchVmap.utils import to_torch_tensors, to_torch_tensor, \
                                  torch_jacobian
from shared.ITest import ITest
from shared.BAData import BAInput, BAOutput
from shared.BASparseMat import BASparseMat
from shared.defs import BA_NCAMPARAMS
from modules.PyTorchVmap.ba_objective import compute_reproj_err, compute_w_err

import os

if 'OMP_NUM_THREADS' in os.environ:
    torch.set_num_threads(int(os.environ['OMP_NUM_THREADS']))

# torch.vmap and torch.compile can't be used together:
# https://github.com/pytorch/pytorch/issues/100320
# We use vmap in this case


def jac_reproj_err(cam, x, w, feat):
    return torch_jacobian(compute_reproj_err, (cam, x, w), (feat, ))


batched_reproj_err = torch.vmap(compute_reproj_err)
batched_jac_reproj_err = torch.vmap(jac_reproj_err)


def jac_w_err(w):
    return torch_jacobian(compute_w_err, (w, ))


batched_w_err = torch.vmap(compute_w_err)
batched_jac_w_err = torch.vmap(jac_w_err)


class PyTorchVmapBA(ITest):
    '''Test class for BA diferentiation by PyTorch.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.p = len(input.obs)

        self.cams = to_torch_tensor(input.cams, grad_req=True)
        self.x = to_torch_tensor(input.x, grad_req=True)
        self.w = to_torch_tensor(input.w, grad_req=True)
        self.obs = to_torch_tensor(input.obs, dtype=torch.int64)
        self.feats = to_torch_tensor(input.feats)

        self.reproj_error = torch.zeros(2 * self.p, dtype=torch.float64)
        self.w_err = torch.zeros(len(input.w))
        self.jacobian = BASparseMat(len(input.cams), len(input.x), self.p)

    def output(self):
        '''Returns calculation result.'''

        # Postprocess Jacobian into BASparseMat
        J_reproj_error = self.J_reproj_error.detach().numpy()
        J_w_err = self.J_w_err.detach().numpy()
        obs = self.obs.numpy()
        for j in range(self.p):
            camIdx = obs[j, 0]
            ptIdx = obs[j, 1]
            self.jacobian.insert_reproj_err_block(j, camIdx, ptIdx,
                                                  J_reproj_error[j])
        for j in range(self.p):
            self.jacobian.insert_w_err_block(j, J_w_err[j])

        return BAOutput(self.reproj_error.detach().numpy(),
                        self.w_err.detach().numpy(), self.jacobian)

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        with torch.no_grad():
            for i in range(times):
                self.reproj_error = batched_reproj_err(
                    torch.index_select(self.cams, 0, self.obs[:, 0]),
                    torch.index_select(self.x, 0, self.obs[:, 1]),
                    self.w,
                    self.feats,
                )
                self.w_err = batched_w_err(self.w)

                assert self.reproj_error.shape == (self.p, 2)
                assert self.w_err.shape == (self.p, )

                self.reproj_error = self.reproj_error.flatten()

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        for i in range(times):

            self.reproj_error, self.J_reproj_error = batched_jac_reproj_err(
                torch.index_select(self.cams, 0, self.obs[:, 0]),
                torch.index_select(self.x, 0, self.obs[:, 1]),
                self.w,
                self.feats,
            )
            self.w_err, self.J_w_err = batched_jac_w_err(self.w)

            assert self.reproj_error.shape == (self.p, 2)
            assert self.w_err.shape == (self.p, )

            assert self.J_reproj_error.shape == (self.p,
                                                 2 * (BA_NCAMPARAMS + 3 + 1))
            assert self.J_w_err.shape == (self.p, 1)

            self.reproj_error = self.reproj_error.flatten()
            self.J_w_err = self.J_w_err.flatten()
