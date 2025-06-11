//* This file is part of the RACCOON application
//* being developed at Dolbow lab at Duke University
//* http://dolbow.pratt.duke.edu

#pragma once

#include "SmallDeformationElasticityModel.h"
#include "DerivativeMaterialPropertyNameInterface.h"

class SmallDeformationATHDecompositionElasticity : public SmallDeformationElasticityModel,
                                            public DerivativeMaterialPropertyNameInterface
{
public:
  static InputParameters validParams();

  SmallDeformationATHDecompositionElasticity(const InputParameters & parameters);

  virtual ADRankTwoTensor computeStress(const ADRankTwoTensor & strain) override;

protected:
private:
  // @{ Decomposition methods
  virtual ADRankTwoTensor computeStressATHDecomposition(const ADRankTwoTensor & strain);
  // virtual ADRankTwoTensor computeStressSpectralDecomposition(const ADRankTwoTensor & strain);
  // virtual ADRankTwoTensor computeStressVolDevDecomposition(const ADRankTwoTensor & strain);
  // @}

  /// The bulk modulus
  const ADMaterialProperty<Real> & _K;

  /// The shear modulus
  const ADMaterialProperty<Real> & _G;

  /// Name of the phase-field variable
  const VariableName _d_name;

  /// The name of the nucleation phase
  // const MaterialPropertyName _xi_name;
  // const ADMaterialProperty<Real> & _xi;

  // @{ Strain energy density driving nucleation            #and its derivative w/r/t damage
  const MaterialPropertyName _psie_n_name;
  ADMaterialProperty<Real> & _psie_n;
  ADMaterialProperty<Real> & _psie_n_active;
  // ADMaterialProperty<Real> & _dpsie_dd;
  // @}

  // @{ Strain energy density driving propagation            #and its derivative w/r/t damage
  const MaterialPropertyName _psie_p_name;
  ADMaterialProperty<Real> & _psie_p;
  ADMaterialProperty<Real> & _psie_p_active;
  // ADMaterialProperty<Real> & _dpsie_dd;

  // @{ The nucleation degradation function and its derivative w/r/t nucleation
  const MaterialPropertyName _h_name;
  const ADMaterialProperty<Real> & _h;
  // const ADMaterialProperty<Real> & _dh_dxi;
  // @}

  // @{ The propagation degradation function and its derivative w/r/t damage
  const MaterialPropertyName _g_name;
  const ADMaterialProperty<Real> & _g;
  // const ADMaterialProperty<Real> & _dg_dd;
  // @}

  // Strength surface shaping parameters
  const ADMaterialProperty<Real> & _q1;
  const ADMaterialProperty<Real> & _q2;

  // /// Decomposittion types
  // const enum class Decomposition { none, spectral, voldev } _decomposition;
};
