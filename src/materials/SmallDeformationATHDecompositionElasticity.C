//* This file is part of the RACCOON application
//* being developed at Dolbow lab at Duke University
//* http://dolbow.pratt.duke.edu

#include "SmallDeformationATHDecompositionElasticity.h"
#include "RaccoonUtils.h"
#include "RankTwoTensorImplementation.h"

registerMooseObject("raccoonApp", SmallDeformationATHDecompositionElasticity);

InputParameters
SmallDeformationATHDecompositionElasticity::validParams()
{
  InputParameters params = SmallDeformationElasticityModel::validParams();
  params.addClassDescription("Isotropic elasticity under small strain asumptions.");

  params.addRequiredParam<MaterialPropertyName>("bulk_modulus", "The bulk modulus $K$");
  params.addRequiredParam<MaterialPropertyName>("shear_modulus", "The shear modulus $G$");

  params.addRequiredCoupledVar("phase_field", "Name of the phase-field (damage) variable");
  // params.addParam<MaterialPropertyName>(
  //     "nucleation_phase",
  //     "xi",
  //     "Name of the nucleation phase");
  params.addParam<MaterialPropertyName>(
      "strain_energy_density_nucleation",
      "psie_n",
      "Name of the strain energy density driving the nucleation computed by this material model");
  params.addParam<MaterialPropertyName>(
      "strain_energy_density_propagation",
      "psie_p",
      "Name of the strain energy density driving the propagation computed by this material model");
  params.addParam<MaterialPropertyName>(
      "propagation_degradation_function", "g", "The propagation degradation function");
  params.addParam<MaterialPropertyName>(
      "nucleation_degradation_function", "h", "The nucleation degradation function");

  params.addParam<MaterialPropertyName>(
      "SS_param_1", "q1", "first parameter to control the shape of the strength surface");
  params.addParam<MaterialPropertyName>(
      "SS_param_2", "q2", "2nd parameter to control the shape of the strength surface");

  return params;
}

SmallDeformationATHDecompositionElasticity::SmallDeformationATHDecompositionElasticity(
    const InputParameters & parameters)
  : SmallDeformationElasticityModel(parameters),
    DerivativeMaterialPropertyNameInterface(),
    _K(getADMaterialPropertyByName<Real>(prependBaseName("bulk_modulus", true))),
    _G(getADMaterialPropertyByName<Real>(prependBaseName("shear_modulus", true))),

    _d_name(getVar("phase_field", 0)->name()),

    // _xi_name(prependBaseName("nucleation_phase", true)),
    // _xi(declareADProperty<Real>(_xi_name)),

    // The strain energy density for nucleation               #and its derivatives
    _psie_n_name(prependBaseName("strain_energy_density_nucleation", true)),
    _psie_n(declareADProperty<Real>(_psie_n_name)),
    _psie_n_active(declareADProperty<Real>(_psie_n_name + "_active")),

    // The strain energy density for propagation                #and its derivatives
    _psie_p_name(prependBaseName("strain_energy_density_propagation", true)),
    _psie_p(declareADProperty<Real>(_psie_p_name)),
    _psie_p_active(declareADProperty<Real>(_psie_p_name + "_active")),
    // _dpsie_dd(declareADProperty<Real>(derivativePropertyName(_psie_name, {_d_name}))),

    // The nucleation degradation function and its derivatives
    _h_name(prependBaseName("nucleation_degradation_function", true)),
    _h(getADMaterialProperty<Real>(_h_name)),
    // _dh_dxi(getADMaterialProperty<Real>(derivativePropertyName(_h_name, {_xi_name}))),

    // The propagation degradation function and its derivatives
    _g_name(prependBaseName("propagation_degradation_function", true)),
    _g(getADMaterialProperty<Real>(_g_name)),
    // _dg_dd(getADMaterialProperty<Real>(derivativePropertyName(_g_name, {_d_name}))),

    _q1(getADMaterialProperty<Real>("SS_param_1")),
    _q2(getADMaterialProperty<Real>("SS_param_2"))

// _decomposition(getParam<MooseEnum>("decomposition").getEnum<Decomposition>())
{
}

ADRankTwoTensor
SmallDeformationATHDecompositionElasticity::computeStress(const ADRankTwoTensor & strain)
{
  ADRankTwoTensor stress;

  stress = computeStressATHDecomposition(strain);

  return stress;
}

ADRankTwoTensor
SmallDeformationATHDecompositionElasticity::computeStressATHDecomposition(
    const ADRankTwoTensor & strain)
{
  // const ADReal lambda = _K[_qp] - 2 * _G[_qp] / LIBMESH_DIM;
  const ADRankTwoTensor I2(ADRankTwoTensor::initIdentity);
  ADRankTwoTensor strain_sq = strain.square();
  ADReal strain_sq_tr = strain_sq.trace();
  ADReal strain_tr = strain.trace();
  auto I_2 = 0.5 * (strain_tr * strain_tr - strain_sq_tr);
  ADRankTwoTensor strain_dev = strain.deviatoric();
  auto J_2 = 0.5 * strain_dev.doubleContraction(strain_dev);

  // Principal strains and directions
  ADRankTwoTensor principal_dirs;
  std::vector<ADReal> principal_strains(LIBMESH_DIM);
  strain.symmetricEigenvaluesEigenvectors(principal_strains, principal_dirs);

  // evaluating require quantities
  ADRankTwoTensor principal_strain_tensor;
  principal_strain_tensor.fillFromInputVector(principal_strains);
  ADRankTwoTensor principal_strain_tensor_squared = principal_strain_tensor.square();
  auto sum_of_squared_ps = principal_strain_tensor_squared.trace();

  ADRankTwoTensor principal_strain_tensor_pos;
  principal_strain_tensor_pos.fillFromInputVector(RaccoonUtils::Macaulay(principal_strains));
  ADRankTwoTensor principal_strain_tensor_pos_squared = principal_strain_tensor_pos.square();
  auto sum_of_squared_pos_ps = principal_strain_tensor_pos_squared.trace();

  // std::cout << "sum of sq pos ps, sum of sq ps " << raw_value(sum_of_squared_pos_ps) << " "
  //           << raw_value(sum_of_squared_ps) << std::endl;

  // Spectral decomposition to get E+
  ADRankTwoTensor strain_pos = RaccoonUtils::spectralDecomposition(strain);

  // Stress
  ADRankTwoTensor stress_n_intact = _q1[_qp] * _K[_qp] * strain_pos +
                                    _q2[_qp] * _K[_qp] * (strain.trace() * I2 - strain) +
                                    2 * _G[_qp] * strain.deviatoric();
  ADRankTwoTensor stress_p_intact = _K[_qp] * (strain - _q1[_qp] * strain_pos) +
                                    (1 - _q2[_qp]) * _K[_qp] * (strain.trace() * I2 - strain);
  ADRankTwoTensor stress = _g[_qp] * _h[_qp] * stress_n_intact + _g[_qp] * stress_p_intact;

  // Strain energy density

  _psie_n_active[_qp] = 0.5 * _K[_qp] * _q1[_qp] * sum_of_squared_pos_ps +
                        _K[_qp] * _q2[_qp] * I_2 + 2.0 * _G[_qp] * J_2;
  _psie_p_active[_qp] = 0.5 * _K[_qp] * (sum_of_squared_ps - _q1[_qp] * sum_of_squared_pos_ps) +
                        _K[_qp] * (1 - _q2[_qp]) * I_2;
  _psie_n[_qp] = _g[_qp] * _h[_qp] * _psie_n_active[_qp];
  _psie_p[_qp] = _g[_qp] * _psie_p_active[_qp];

  return stress;
}
