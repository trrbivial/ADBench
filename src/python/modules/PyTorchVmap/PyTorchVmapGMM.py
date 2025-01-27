# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import numpy as np
import torch

from modules.PyTorchVmap.utils import to_torch_tensors, torch_jacobian
from shared.ITest import ITest
from shared.GMMData import GMMInput, GMMOutput
from modules.PyTorchVmap.gmm_objective import gmm_objective

import os

if 'OMP_NUM_THREADS' in os.environ:
    torch.set_num_threads(int(os.environ['OMP_NUM_THREADS']))


# If using torch.compile, some cases will crash
#gmm_objective_compiled = torch.compile(gmm_objective)
gmm_objective_compiled = gmm_objective

#gmm_jacobian_compiled = torch.compile(lambda inputs, params: torch_jacobian(gmm_objective, inputs, params))
# jacobian can't be compiled: RuntimeError: Cannot access data pointer of Tensor that doesn't have storage
gmm_jacobian_compiled = lambda inputs, params: torch_jacobian(gmm_objective, inputs, params)

class PyTorchVmapGMM(ITest):
    '''Test class for GMM differentiation by PyTorch.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.inputs = to_torch_tensors(
            (input.alphas, input.means, input.icf),
            grad_req = True
        )

        self.params = to_torch_tensors(
            (input.x, input.wishart.gamma, input.wishart.m)
        )

        self.objective = torch.zeros(1)
        self.gradient = torch.empty(0)

    def output(self):
        '''Returns calculation result.'''

        return GMMOutput(self.objective.item(), self.gradient.detach().numpy())

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        with torch.no_grad():
            for i in range(times):
                self.objective = gmm_objective_compiled(*self.inputs, *self.params)

    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for i in range(times):
            self.objective, self.gradient = gmm_jacobian_compiled(
                self.inputs,
                self.params
            )
