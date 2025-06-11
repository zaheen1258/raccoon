//* This file is part of the RACCOON application
//* being developed at Dolbow lab at Duke University
//* http://dolbow.pratt.duke.edu

#include "ADPFFDiffusion.h"

registerMooseObject("raccoonApp", ADPFFDiffusion);

InputParameters
ADPFFDiffusion::validParams()
{
  InputParameters params = ADKernel::validParams();
  params += BaseNameInterface::validParams();
  params.addClassDescription("The diffusion term in the phase-field evolution equation. The weak "
                             "form is $(\\grad w, \\dfrac{2\\Gc l}{c_0} \\grad d)$.");

  params.addParam<MaterialPropertyName>(
      "fracture_toughness", "Gc", "The fracture toughness $\\Gc$");
  params.addParam<MaterialPropertyName>(
      "normalization_constant", "c0", "The normalization constant $c_0$");
  params.addParam<MaterialPropertyName>(
      "normalization_constant_ATH", 1, "The normalization constant $c_1$ for ATH functional");
  params.addParam<MaterialPropertyName>(
      "regularization_length", "l", "The phase-field regularization length");
  return params;
}

ADPFFDiffusion::ADPFFDiffusion(const InputParameters & parameters)
  : ADKernel(parameters),
    BaseNameInterface(parameters),
    _Gc(getADMaterialProperty<Real>(prependBaseName("fracture_toughness", true))),
    _c0(getADMaterialProperty<Real>(prependBaseName("normalization_constant", true))),
    _c1(getADMaterialProperty<Real>(prependBaseName("normalization_constant_ATH", true))),
    _l(getADMaterialProperty<Real>(prependBaseName("regularization_length", true)))
{
}

ADReal
ADPFFDiffusion::computeQpResidual()
{
  ADReal value = _grad_test[_i][_qp] * _grad_u[_qp];

  // return 2 * _Gc[_qp] * _l[_qp] / _c0[_qp] / _c1[_qp] * value;
  return  _Gc[_qp] * _l[_qp] / _c0[_qp] / _c1[_qp] * value;
}
