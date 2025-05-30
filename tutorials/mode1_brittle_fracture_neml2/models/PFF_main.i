# [Settings]
#   additional_libraries = '/Users/knasir/projects/neml2_local/neml2/build/release/src/neml2/libneml2_user_tensor_Debug.dylib'
# []

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

[Models] # Computes psi_active to send to the fracture app and degraded stress for output with new phase value 
   [degrade]
    type = PowerDegradationFunction
    phase = 'state/d'
    degradation = 'state/g'
    power = 'p'
  []
  [sed0]
    type = LinearIsotropicStrainEnergyDensity
    strain = 'forces/E'
    strain_energy_density = 'state/psie0'
    coefficient_types = 'YOUNGS_MODULUS POISSONS_RATIO'
    coefficients = '2.1e5 0.3'
  []
  [sed]
    type = ScalarMultiplication
    from_var = 'state/g state/psie0'
    to_var = 'state/psie'
  []
  [energy] # this guy maps from (strain, d) -> degraded energy
    type = ComposedModel
    models = 'degrade sed0 sed'
    # additional_outputs = 'state/psie0'
  []
  [stress]
    type = Normality
    model = 'energy'
    function = 'state/psie'
    from = 'forces/E'
    to = 'state/S'
  []
  [model_main]
    type = ComposedModel
    models = 'stress sed0'
    additional_outputs = 'state/psie0'
  []
  ####################################
  [sed_frac]
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
  [energy_frac] # this guy maps from (strain, d) -> energy
    type = ComposedModel
    models = 'degrade sed_frac cracked sum'
  []
  [dpsidd]
    type = Normality
    model = 'energy_frac'
    function = 'state/psi'
    from = 'state/d'
    to = 'state/dpsi_dd'
  []
  # [d2psidd2]
  #   type = Normality
  #   model = 'dpsidd'
  #   function = 'state/dpsi_dd'
  #   from = 'state/d'
  #   to = 'state/d2psi_dd2'
  # []
  # [model_frac]
  #   type = ComposedModel
  #   models = 'dpsidd d2psidd2'
  #   additional_outputs = 'state/dpsi_dd'
  # []
[]