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
    coupled_variables = 'xi'
    constant_names = 'ze'
    constant_expressions = '${z}'
    derivative_order = 2
  []
  [nucleation_degradation]
    type = ADDerivativeParsedMaterial
    property_name = h
    expression = 'exp(-k*xi)'
    coupled_variables = 'xi'
    constant_names = 'k'
    constant_expressions = '${k}'
    derivative_order = 2
  []
  [prop_degradation]
    type = PowerDegradationFunction
    property_name = g
    expression = (1-d)^p+eta
    phase_field = d
    parameter_names = 'p eta '
    parameter_values = '2 1e-6'
  []
  [crack_geometric]
    type = CrackGeometricFunction
    property_name = alpha
    expression = 'd'
    phase_field = d
  []
  [psi]
    type = ADDerivativeParsedMaterial
    property_name = psi
    expression = 'alpha*beta*Gc/c0/c1/l+g*h*psie_n_active+g*psie_p_active'
    coupled_variables = 'd psie_n_active psie_p_active xi'
    material_property_names = 'alpha(d) beta(xi) g(d) h(xi) Gc c0 c1 l'
    # constant_names = 'S'
    # constant_expressions = '${S}'
    derivative_order = 2
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
  print_linear_residuals = false
[]
