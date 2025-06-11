# E = 2.1e5
# nu = 0.3
# K = '${fparse E/3/(1-2*nu)}'
# G = '${fparse E/2/(1+nu)}'
K = 4.4e3
G = 4.3e4

Gc = 9.1e-2
l = 0.2

[MultiApps]
  [fracture]
    type = TransientMultiApp
    input_files = fracture_V2.i
    cli_args = 'Gc=${Gc};l=${l}'
    execute_on = 'TIMESTEP_END'
  []
[]

[Transfers]
  [from_d]
    type = MultiAppCopyTransfer
    from_multi_app = 'fracture'
    variable = 'd xi'
    source_variable = 'd xi'
  []
  [to_psie_active]
    type = MultiAppCopyTransfer
    to_multi_app = 'fracture'
    variable = 'psie_n_active  psie_p_active'
    source_variable = 'psie_n_active  psie_p_active'
  []
[]

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 10
    ny = 5
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
  [disp_x]
  []
  [disp_y]
  []
[]

[AuxVariables]
  [fy]
  []
  [d]
  []
  [xi]
    order = CONSTANT
    family = MONOMIAL
  []
  # [psi]
  #   order = CONSTANT
  #   family = MONOMIAL
  # []
[]

[Kernels]
  [solid_x]
    type = ADStressDivergenceTensors
    variable = disp_x
    component = 0
  []
  [solid_y]
    type = ADStressDivergenceTensors
    variable = disp_y
    component = 1
    save_in = fy
  []
[]

[BCs]
  [ydisp]
    type = FunctionDirichletBC
    variable = disp_y
    boundary = top
    function = 't'
  []
  [yfix]
    type = DirichletBC
    variable = disp_y
    boundary = noncrack
    value = 0
  []
  [xfix]
    type = DirichletBC
    variable = disp_x
    boundary = top
    value = 0
  []
[]

[Materials]
  [bulk]
    type = ADGenericConstantMaterial
    prop_names = 'K G Gc l'
    prop_values = '${K} ${G} ${Gc} ${l}'
  []
  # [c1]
  #   type = ADDerivativeParsedMaterial
  #   property_name = c1
  #   expression = '(S*c0*l)/ze/Gc'
  #   material_property_names = 'c0 l Gc'
  #   constant_names = 'S    ze'
  #   constant_expressions = '0.01  1.0' 
  #   derivative_order = 1
  # []
  # [potential_well]
  #   type = ADDerivativeParsedMaterial
  #   property_name = beta
  #   expression = 'xi^(-ze)'
  #   coupled_variables = 'xi'
  #   constant_names = 'ze'
  #   constant_expressions = '1'
  #   derivative_order = 2
  # []
  [nucleation_degradation]
    type = ADDerivativeParsedMaterial
    property_name = h
    expression = 'exp(-k*xi)'
    coupled_variables = 'xi'
    constant_names = 'k'
    constant_expressions = '1'
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
  # [crack_geometric]
  #   type = CrackGeometricFunction
  #   property_name = alpha
  #   expression = 'd'
  #   phase_field = d
  # []
  [strain]
    type = ADComputeSmallStrain
  []
  # [nucleation]
  #   type = ADNucleationPhaseCalculator
  #   nucleation_threshold = 0.01          #S
  #   crack = alpha                          
  #   propagation_degradation = g
  #   nucleation_strain_energy_density = 'psie_n_active'  
  #   fracture_toughness = Gc
  #   normalization_constant = c0         
  #   normalization_constant_ATH = c1    
  #   regularization_length = l
  #   nucleation_degradation_rate = 3.0    #k
  #   transition_parameter = 1.0           #ze
  #   output_properties = 'xi'
  #   outputs = exodus
  # []
  [elasticity]
    type = SmallDeformationATHDecompositionElasticity
    bulk_modulus = K
    shear_modulus = G
    phase_field = d
    # nucleation_phase = xi
    propagation_degradation_function = g
    nucleation_degradation_function = h
    SS_param_1 = 9.974
    SS_param_2 = 1.9
    output_properties = 'elastic_strain psie_n_active psie_p_active'
    outputs = exodus
  []
  [stress]
    type = ComputeSmallDeformationStress
    elasticity_model = elasticity
    output_properties = 'stress'
    outputs = exodus
  []
[]

[Postprocessors]
  [Fy]
    type = NodalSum
    variable = fy
    boundary = top
  []
  [psien_val]
		type = ADElementAverageMaterialProperty
		mat_prop = psie_n_active
	[]
  [psip_val]
		type = ADElementAverageMaterialProperty
		mat_prop = psie_p_active
	[]
  [xi_val]
    type = ElementAverageValue
    variable = xi
  []
[]

[Executioner]
  type = Transient

  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = 'lu       superlu_dist                 '
  automatic_scaling = true

  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-10

  dt = 1e-2
  end_time = 2

  fixed_point_max_its = 20
  accept_on_max_fixed_point_iteration = true
  fixed_point_rel_tol = 1e-8
  fixed_point_abs_tol = 1e-10
[]

[Outputs]
  exodus = true
  csv = true
  print_linear_residuals = false
[]
