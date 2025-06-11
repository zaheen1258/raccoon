[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 30
    ny = 15
    ymax = 0.5
  []
  [noncrack]
    type = BoundingBoxNodeSetGenerator
    input = gen
    new_boundary = noncrack
    bottom_left = '0.5 0 0'
    top_right = '1 0 0'
  []
  construct_side_list_from_node_list = true
[]

[Adaptivity]
  marker = marker
  initial_marker = marker
  initial_steps = 2
  stop_time = 0
  max_h_level = 2
  [Markers]
    [marker]
      type = BoxMarker
      bottom_left = '0.4 0 0'
      top_right = '1 0.05 0'
      outside = DO_NOTHING
      inside = REFINE
    []
  []
[]

[Variables]
  [d]
  []
[]

[AuxVariables]
  [bounds_dummy]
  []
  [psie_n_active]
    order = CONSTANT
    family = MONOMIAL
  []
  [psie_p_active]
    order = CONSTANT
    family = MONOMIAL
  []
  [xi]
    order = CONSTANT
    family = MONOMIAL
    [AuxKernel]
      type = ADMaterialRealAux
      property = xi
    []
  []
[]

[Bounds]
  [irreversibility]
    type = VariableOldValueBounds
    variable = bounds_dummy
    bounded_variable = d
    bound_type = lower
  []
  [upper]
    type = ConstantBounds
    variable = bounds_dummy
    bounded_variable = d
    bound_type = upper
    bound_value = 1
  []
[]

[Kernels]
  [diff]
    type = ADPFFDiffusion
    variable = d
    fracture_toughness = Gc
    regularization_length = l
    normalization_constant = c0
    normalization_constant_ATH = c1
  []
  [source]
    type = ADPFFSource
    variable = d
    free_energy = psi
  []
[]

[Materials]
  [fracture_properties]
    type = ADGenericConstantMaterial
    prop_names = 'Gc l'
    prop_values = '${Gc} ${l}'
  []
 [c1]
    type = ADDerivativeParsedMaterial
    property_name = c1
    expression = '(S*c0*l)/ze/Gc'
    material_property_names = 'c0 l Gc'
    constant_names = 'S    ze'
    constant_expressions = '${S}  ${z}' 
    derivative_order = 2
  []
  [potential_well]
    type = ADDerivativeParsedMaterial
    property_name = beta
    expression = 'xi^(-ze)'
    material_property_names = 'xi'
    constant_names = 'ze'
    constant_expressions = '${z}'
    output_properties = 'beta'
    derivative_order = 2
  []
  [nucleation_degradation]
    type = ADDerivativeParsedMaterial
    property_name = h
    expression = 'exp(-k*xi)'
    material_property_names = 'xi'
    constant_names = 'k'
    constant_expressions = '${k}'
    output_properties = 'h'
    derivative_order = 2
  []
  [prop_degradation]
    type = PowerDegradationFunction
    property_name = g
    expression = (1-d)^p+eta
    phase_field = d
    parameter_names = 'p eta '
    parameter_values = '2 1e-10'
  []
  [crack_geometric]
    type = CrackGeometricFunction
    property_name = alpha
    expression = 'd'
    phase_field = d
  []
  [psie_n_active_mat_prop]
  type = ADDerivativeParsedMaterial
  property_name = psie_n_active
  coupled_variables = 'psie_n_active'
  expression = 'psie_n_active'
  derivative_order = 2
  # outputs = exodus
  []
  [nucleation]
    type = ADNucleationPhaseCalculator
    nucleation_threshold = ${S}        #S
    crack = alpha                          
    propagation_degradation = g
    nucleation_strain_energy_density = 'psie_n_active'  
    fracture_toughness = Gc
    normalization_constant = c0         
    normalization_constant_ATH = c1    
    regularization_length = l
    nucleation_degradation_rate = ${k}    #k
    transition_parameter = ${z}         #ze
    output_properties = 'xi'
    # outputs = exodus
  []
  [psi]
    type = ADDerivativeParsedMaterial
    property_name = psi
    expression = 'alpha*beta*Gc/c0/c1/l+g*h*psie_n_active+g*psie_p_active'
    coupled_variables = 'd psie_n_active psie_p_active'
    material_property_names = 'alpha(d) beta(xi) g(d) h(xi) Gc c0 c1 l xi'
    constant_names = 'S'
    constant_expressions = '${S}'
    output_properties = 'psi'
    derivative_order = 2
  []
[]
[Postprocessors]
	[nucleation_phase]
		type = ADElementAverageMaterialProperty
		mat_prop = xi
	[]
  [beta_prop]
		type = ADElementAverageMaterialProperty
		mat_prop = beta
	[]
  [psi_val]
		type = ADElementAverageMaterialProperty
		mat_prop = psi
	[]
  [h_val]
		type = ADElementAverageMaterialProperty
		mat_prop = h
	[]
[]

[Executioner]
  type = Transient

  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -snes_type'
  petsc_options_value = 'lu       superlu_dist                  vinewtonrsls'
  automatic_scaling = true

  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-10
[]

[Outputs]
  # csv = true
  print_linear_residuals = false
[]
