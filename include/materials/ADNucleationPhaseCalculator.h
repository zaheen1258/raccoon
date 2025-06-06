//* This file is part of the RACCOON application
//* being developed at Dolbow lab at Duke University
//* http://dolbow.pratt.duke.edu

#pragma once

#include "Material.h"
#include "DerivativeMaterialInterface.h"

/**
 * Class to evaluate the crack geometric function and automatically provide all derivatives.
 */
class ADNucleationPhaseCalculator : public DerivativeMaterialInterface<Material>
{
public:
  static InputParameters validParams();

  ADNucleationPhaseCalculator(const InputParameters & parameters);

protected:
  
  virtual void initQpStatefulProperties() override;
  
  void computeQpProperties() override;

private:

  /// The nucleation phase 
  ADMaterialProperty<Real> & _xi;

  /// The nucleation phase old
  const MaterialProperty<Real> & _xi_old;

  /// Material threshold for crack nucleation
  const ADMaterialProperty<Real> & _S;

  /// Value of crack geometric function
  const ADMaterialProperty<Real> & _alpha;

  /// Value of the propagation degradation function
  const ADMaterialProperty<Real> & _g;

  /// Part of the strain energy density responsible for crack nucleation
  const ADMaterialProperty<Real> & _psi_n;

  /// The fracture toughness
  const ADMaterialProperty<Real> & _Gc;

  /// The normalization constant
  const ADMaterialProperty<Real> & _c0;

  /// The normalization constant for the ATH functional
  const ADMaterialProperty<Real> & _c1;

  /// The regularization length
  const ADMaterialProperty<Real> & _l;

  /// The nucleation degradation rate
  const ADMaterialProperty<Real> & _k;

  /// The transition parameter
  const ADMaterialProperty<Real> & _z;

};
