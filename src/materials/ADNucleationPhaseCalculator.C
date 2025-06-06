//* This file is part of the RACCOON application
//* being developed at Dolbow lab at Duke University
//* http://dolbow.pratt.duke.edu

#include "ADNucleationPhaseCalculator.h"

registerMooseObject("raccoonApp", ADNucleationPhaseCalculator);

InputParameters
ADNucleationPhaseCalculator::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription("This class claculates the nucleation phase \\f$\\xi\\f$ given the "
                             "material threshold, nucleation strain energy density and the values "
                             "of degradation and crack geometric function");

  params.addParam<MaterialPropertyName>(
      "nucleation_threshold", "S", "Name of the material specific threshold for nucleation$");

  params.addParam<MaterialPropertyName>("crack", "alpha", "Name of the crack geometric function");

  params.addParam<MaterialPropertyName>(
      "propagation_degradation", "g", "Name of the propagation degradation function");

  params.addParam<MaterialPropertyName>(
      "nucleation_strain_energy_density",
      "psi_n",
      "Name of the strain energy density responsible for crack nucleation");

  params.addParam<MaterialPropertyName>(
      "fracture_toughness", "Gc", "The fracture toughness \\f$\\Gc\\f$");

  params.addParam<MaterialPropertyName>(
      "normalization_constant", "c0", "The normalization constant \\f$c_0\\f$");

  params.addParam<MaterialPropertyName>(
      "normalization_constant_ATH", "c1", "The normalization constant \\f$c_1\\f$");

  params.addParam<MaterialPropertyName>(
      "regularization_length", "l", "The phase-field regularization length");

  params.addParam<MaterialPropertyName>(
      "nucleation_degradation_rate", "k", "controls the rate of nucleation degradation");

  params.addParam<MaterialPropertyName>(
      "transition_parameter", "z", "controls the onset of propagation");

  return params;
}

ADNucleationPhaseCalculator::ADNucleationPhaseCalculator(const InputParameters & parameters)
  : DerivativeMaterialInterface<Material>(parameters),
    _xi(declareADProperty<Real>("xi")),
    _xi_old(getMaterialPropertyOld<Real>("xi")),
    _S(getADMaterialProperty<Real>("nucleation_threshold")),
    _alpha(getADMaterialProperty<Real>("crack")),
    _g(getADMaterialProperty<Real>("propagation_degradation")),
    _psi_n(getADMaterialProperty<Real>("nucleation_strain_energy_density")),
    _Gc(getADMaterialProperty<Real>("fracture_toughness")),
    _c0(getADMaterialProperty<Real>("normalization_constant")),
    _c1(getADMaterialProperty<Real>("normalization_constant_ATH")),
    _l(getADMaterialProperty<Real>("regularization_length")),
    _k(getADMaterialProperty<Real>("nucleation_degradation_rate")),
    _z(getADMaterialProperty<Real>("transition_parameter"))
{
}

void
ADNucleationPhaseCalculator::initQpStatefulProperties()
{
  _xi[_qp] = 1e-8;
}

void
ADNucleationPhaseCalculator::computeQpProperties()
{
  /// calculating the nucleation envelope
  auto F_n = _S[_qp] -
             (_Gc[_qp] / _c0[_qp] / _c1[_qp] / _l[_qp]) * _alpha[_qp] * _z[_qp] *
                 std::pow(_xi[_qp], -(_z[_qp] + 1.0)) -
             _k[_qp] * _g[_qp] * std::exp(-_k[_qp] * _xi[_qp]) * _psi_n[_qp];

  /// Checking if the nucleation phase is allowed to evolve or not
  if (F_n >= 0)
    _xi[_qp] = _xi_old[_qp];
  else
  {
    ADReal R = 0.0;
    unsigned int k = 0;
    Real tol = 1e-16;

    // Starting the Newton-Raphson loop
    while (std::abs(R) > tol || k == 0)
    {
      if (++k > 100)
      {
        std::cerr << "Max iterations reached.\n";
        break;
      }
      R = _S[_qp] -
          (_Gc[_qp] / _c0[_qp] / _c1[_qp] / _l[_qp]) * _alpha[_qp] * _z[_qp] *
              std::pow(_xi[_qp], -(_z[_qp] + 1.0)) -
          _k[_qp] * _g[_qp] * std::exp(-_k[_qp] * _xi[_qp]) * _psi_n[_qp];

      auto J = _S[_qp] +
               (_Gc[_qp] / _c0[_qp] / _c1[_qp] / _l[_qp]) * _alpha[_qp] * _z[_qp] *
                   (_z[_qp] + 1.0) * std::pow(_xi[_qp], -(_z[_qp] + 2.0)) +
               _k[_qp] * _k[_qp] * _g[_qp] * std::exp(-_k[_qp] * _xi[_qp]) * _psi_n[_qp];

      _xi[_qp] = _xi[_qp] - (R / J);
    }
  }
}
