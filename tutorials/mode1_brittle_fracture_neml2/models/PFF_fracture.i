# [Settings]
#   additional_libraries = '/Users/knasir/projects/neml2_local/neml2/build/release/src/neml2/libneml2_user_tensor_Debug.dylib'
# []

## Computes the dpsi_dd for the PFFSource kernel

[Tensors]
  [p]
    type = Scalar
    values = 2
  []
  [GcbylbyCo]
    type = Scalar
    values = 67.5 # Gc/l/Co with Gc = 2.7 N/m, l = 0.02 mm, Co = 2
  []
[]

[Models]
  # strain energy density: g * psie0
  [degrade]
    type = PowerDegradationFunction
    phase = 'state/d'
    degradation = 'state/g'
    power = 'p'
  []
  [sed]
    type = ScalarMultiplication
    from_var = 'state/g state/psie0'
    to_var = 'state/psie'
  []
  # crack geometric function: alpha
  [cracked]
    type = CrackGeometricFunctionAT2
    phase = 'state/d'
    crack = 'state/alpha'
  []
  # total energy
  [sum]
    type = ScalarLinearCombination
    from_var = 'state/alpha state/psie'
    to_var = 'state/psi'
    coefficients = 'GcbylbyCo 1'
  []
  [energy] # this guy maps from (strain, d) -> energy
    type = ComposedModel
    models = 'degrade sed cracked sum'
  []
  # Calculate dsi_dd and d2psi_dd
  [dpsidd]
    type = Normality
    model = 'energy'
    function = 'state/psi'
    from = 'state/d'
    to = 'state/dpsi_dd'
  []
  [d2psidd2]
    type = Normality
    model = 'dpsidd'
    function = 'state/dpsi_dd'
    from = 'state/d'
    to = 'state/d2psi_dd2'
  []
  [model]
    type = ComposedModel
    models = 'dpsidd d2psidd2'
    additional_outputs = 'state/dpsi_dd'
  []
[]