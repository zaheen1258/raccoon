[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 2
  ny = 2
  xmax = 1
  ymax = 1
[]

[Problem]
  solve = false
[]

[Variables]
  [u]
  []
[]

[Functions]
  [psi_n_func]
    type = ParsedFunction
    expression = 't'
  []
[]


[Materials]
  [increasing_psin]
    type = ADGenericFunctionMaterial
    prop_names = psi_n
    prop_values = psi_n_func
  []

  [nucleation]
    type = ADNucleationPhaseCalculator
    nucleation_threshold = 0.01
    crack = 0.0                               # alpha value
    # potential_well = 'beta'
    propagation_degradation = 1.0
    # nucleation_degradation = 'h'
    nucleation_strain_energy_density = 'psi_n'  #0.01  #enough to evaluate F_n -ve
    fracture_toughness = 0.02
    normalization_constant = 2.666667         #c0 = 8/3
    normalization_constant_ATH = 1.333333     #c1 = 4/3
    regularization_length = 1.0
    nucleation_degradation_rate = 3.0
    transition_parameter = 1.0
    output_properties = 'xi'
    outputs = exodus
  []
[]

[Postprocessors]
	[nucleation_phase]
		type = ADElementAverageMaterialProperty
		mat_prop = xi
	[]
[]

[Executioner]
  type = Transient
  dt = 1e-3
  end_time = 0.5
[]

[Outputs]
  exodus = true
[]