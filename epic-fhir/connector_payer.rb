# frozen_string_literal: true

# ============================================================================
# Mock Epic on FHIR — Payer (Workato Connector SDK)
# ============================================================================
#
# A SELF-CONTAINED mock of an Epic-on-FHIR (HL7 FHIR R4) connector, built for
# live demos. It mirrors the FHIR REST API surface (read / search / create /
# update / delete on any resourceType) but serves EMBEDDED clinical data:
#
#   * No external HTTP calls are ever made (no get/post/put/etc).
#   * No real Epic/FHIR auth is required (authorization type 'none').
#   * Writes are SIMULATED. A Workato connector is stateless between
#     executions, so create/update/delete synthesize and RETURN a realistic
#     FHIR resource (generated id + meta.versionId/lastUpdated) rather than
#     mutating the embedded dataset.
#
# All seed data lives inline in the `mock_data` method below. Nothing is
# loaded from external files -- the connector is fully self-contained.
#
# Demo flavor: a believable health-plan / PAYER dataset for a health plan
# (BlueRiver Health Plan) covering members, their coverage, submitted claims,
# and explanation-of-benefit (adjudication) records, plus supporting
# Organization, Practitioner, Encounter, and Condition resources that the
# claims and coverage reference. FHIR R4 (4.0.1).
# ============================================================================

{
  title: 'Mock Epic on FHIR (Payer)',

  # --------------------------------------------------------------------------
  # CONNECTION  (no credentials)
  # --------------------------------------------------------------------------
  connection: {
    fields: [
      {
        name: 'fhir_base_label',
        label: 'FHIR base URL label',
        optional: true,
        hint: 'Display-only. A cosmetic label for the mock FHIR endpoint. ' \
              'No effect on behavior -- no requests are ever made.',
        default: 'https://fhir.epic.com/interconnect-fhir-oauth/api/FHIR/R4 (payer mock)'
      }
    ],
    authorization: {
      type: 'none'
    }
  },

  # --------------------------------------------------------------------------
  # TEST  (static success; no network call)
  # --------------------------------------------------------------------------
  test: lambda do |connection|
    {
      status: 'ok',
      connected: true,
      fhirVersion: '4.0.1',
      endpoint: connection['fhir_base_label'].presence ||
                'https://fhir.epic.com/.../api/FHIR/R4 (payer mock)',
      message: 'Mock Epic on FHIR connection succeeded (no external call was made).'
    }
  end,

  # --------------------------------------------------------------------------
  # OBJECT DEFINITIONS  (FHIR R4 resource schemas; all via resource_schema)
  # --------------------------------------------------------------------------
  object_definitions: {
    patient:                 { fields: lambda { |_c, _cf| call('resource_schema', 'Patient') } },
    coverage:                { fields: lambda { |_c, _cf| call('resource_schema', 'Coverage') } },
    claim:                   { fields: lambda { |_c, _cf| call('resource_schema', 'Claim') } },
    explanation_of_benefit:  { fields: lambda { |_c, _cf| call('resource_schema', 'ExplanationOfBenefit') } },
    organization:            { fields: lambda { |_c, _cf| call('resource_schema', 'Organization') } },
    practitioner:            { fields: lambda { |_c, _cf| call('resource_schema', 'Practitioner') } },
    encounter:               { fields: lambda { |_c, _cf| call('resource_schema', 'Encounter') } },
    condition:               { fields: lambda { |_c, _cf| call('resource_schema', 'Condition') } },

    # Dynamic schema: resolves to the fields of whichever resource the user
    # selected in the action/trigger input. Drives I/O for every action.
    dynamic_resource: {
      fields: lambda do |_connection, config_fields|
        call('resource_schema', config_fields['resource'].presence || 'Patient')
      end
    },

    # FHIR Bundle (searchset) wrapper returned by search_resources.
    bundle: {
      fields: lambda do |_connection, config_fields|
        [
          { name: 'resourceType' },
          { name: 'type' },
          { name: 'total', type: 'integer' },
          { name: 'link', type: 'array', of: 'object',
            properties: [{ name: 'relation' }, { name: 'url' }] },
          { name: 'entry', type: 'array', of: 'object', properties: [
            { name: 'fullUrl' },
            { name: 'resource', type: 'object',
              properties: call('resource_schema',
                               config_fields['resource'].presence || 'Patient') },
            { name: 'search', type: 'object', properties: [{ name: 'mode' }] }
          ] }
        ]
      end
    }
  },

  # --------------------------------------------------------------------------
  # PICK LISTS
  # --------------------------------------------------------------------------
  pick_lists: {
    resource_types: lambda do |_connection|
      [
        ['Patient', 'Patient'],
        ['Coverage', 'Coverage'],
        ['Claim', 'Claim'],
        ['ExplanationOfBenefit', 'ExplanationOfBenefit'],
        ['Organization', 'Organization'],
        ['Practitioner', 'Practitioner'],
        ['Encounter', 'Encounter'],
        ['Condition', 'Condition']
      ]
    end
  },

  # --------------------------------------------------------------------------
  # ACTIONS  (resource chosen via pick list; I/O via dynamic_resource)
  # --------------------------------------------------------------------------
  actions: {

    # ---- READ (GET [type]/[id]) -------------------------------------------
    get_resource: {
      title: 'Get resource by ID',
      subtitle: 'Read a single FHIR resource (mock)',
      description: lambda do |_input, _picklist|
        'Read a <span class="provider">FHIR resource</span> by id from ' \
          '<span class="provider">mock Epic on FHIR</span>'
      end,
      help: 'Performs a FHIR read interaction (GET [type]/[id]) against the embedded ' \
            'dataset. Returns the matching resource, or raises a FHIR OperationOutcome ' \
            'not-found error. No external call is made.',

      config_fields: [
        { name: 'resource', label: 'Resource type', control_type: 'select',
          pick_list: 'resource_types', optional: false }
      ],

      input_fields: lambda do |_object_definitions|
        [{ name: 'id', label: 'Resource ID', optional: false,
           hint: 'The logical id of the FHIR resource, e.g. pat-mreynolds.' }]
      end,

      execute: lambda do |_connection, input|
        resource = call('mock_data')[input['resource']]&.find { |r| r['id'] == input['id'] }
        call('not_found!', input['resource'], input['id']) unless resource
        resource
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_resource']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['resource'].presence || 'Patient'].first
      end
    },

    # ---- SEARCH (GET [type]?params) ---------------------------------------
    search_resources: {
      title: 'Search resources',
      subtitle: 'Search FHIR resources -> Bundle (mock)',
      description: lambda do |_input, _picklist|
        'Search <span class="provider">FHIR resources</span> in ' \
          '<span class="provider">mock Epic on FHIR</span>'
      end,
      help: 'Performs a FHIR search interaction and returns a Bundle (type: searchset) with ' \
            'a total and matching entries. Provide structured search-param rows ' \
            '(param / value), a raw FHIR query string (e.g. ' \
            'Patient?family=Reynolds&gender=female), or both. Supports common params and ' \
            'FHIR date prefixes (eq/ge/gt/le/lt). This is a pragmatic "FHIR-search-lite" subset.',

      config_fields: [
        { name: 'resource', label: 'Resource type', control_type: 'select',
          pick_list: 'resource_types', optional: false,
          hint: 'Ignored if a raw query string specifies its own resource type.' }
      ],

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'params', label: 'Search parameters', type: 'array', of: 'object',
            optional: true, hint: 'Each row is ANDed together.',
            properties: [
              { name: 'param', optional: false,
                hint: 'FHIR search param, e.g. family, gender, code, status, patient, date.' },
              { name: 'value', optional: false,
                hint: 'Value; dates may use a prefix, e.g. ge2026-01-01.' }
            ]
          },
          { name: 'query', label: 'Raw FHIR query (optional)', optional: true,
            hint: "e.g. Coverage?beneficiary=pat-mreynolds&status=active" }
        ]
      end,

      execute: lambda do |_connection, input|
        resource_type = input['resource']
        params = Array.wrap(input['params']).map { |p| { 'param' => p['param'], 'value' => p['value'] } }

        if input['query'].present?
          parsed = call('fhir_search', input['query'])
          resource_type = parsed['resourceType'] if parsed['resourceType'].present?
          params += parsed['params']
        end

        matches = call('find_resources', resource_type, params)
        call('build_bundle', resource_type, matches)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['bundle']
      end,

      sample_output: lambda do |_connection, input|
        rt = input['resource'].presence || 'Patient'
        call('build_bundle', rt, call('mock_data')[rt].first(2))
      end
    },

    # ---- CREATE (POST [type]) ---------------------------------------------
    create_resource: {
      title: 'Create resource',
      subtitle: 'Simulate creating a FHIR resource',
      description: lambda do |_input, _picklist|
        'Create a <span class="provider">FHIR resource</span> in ' \
          '<span class="provider">mock Epic on FHIR</span> (simulated)'
      end,
      help: 'SIMULATED WRITE. The connector is stateless and never mutates the embedded ' \
            'dataset. A new FHIR id and meta (versionId 1, lastUpdated now) are generated and ' \
            'the resource is echoed back. Nothing is persisted.',

      config_fields: [
        { name: 'resource', label: 'Resource type', control_type: 'select',
          pick_list: 'resource_types', optional: false }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['dynamic_resource'].reject { |f| %w[id meta].include?(f['name']) }
      end,

      execute: lambda do |_connection, input|
        resource_type = input['resource']
        body = input.except('resource')
        now = call('now_instant')
        body.merge(
          'resourceType' => resource_type,
          'id' => call('generate_fhir_id'),
          'meta' => { 'versionId' => '1', 'lastUpdated' => now }
        )
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_resource']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['resource'].presence || 'Patient'].first
      end
    },

    # ---- UPDATE (PUT [type]/[id]) -----------------------------------------
    update_resource: {
      title: 'Update resource',
      subtitle: 'Simulate updating a FHIR resource',
      description: lambda do |_input, _picklist|
        'Update a <span class="provider">FHIR resource</span> in ' \
          '<span class="provider">mock Epic on FHIR</span> (simulated)'
      end,
      help: 'SIMULATED WRITE. Locates the seed resource by id (or synthesizes one), merges ' \
            'your input over it, increments meta.versionId, sets meta.lastUpdated to now, and ' \
            'returns it. Nothing is persisted.',

      config_fields: [
        { name: 'resource', label: 'Resource type', control_type: 'select',
          pick_list: 'resource_types', optional: false }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['dynamic_resource'].reject { |f| f['name'] == 'meta' }.map do |f|
          f['name'] == 'id' ? f.merge('optional' => false) : f
        end
      end,

      execute: lambda do |_connection, input|
        resource_type = input['resource']
        body = input.except('resource')
        existing = call('mock_data')[resource_type]&.find { |r| r['id'] == body['id'] } || {}
        version = ((existing.dig('meta', 'versionId').to_i.nonzero? || 1) + 1).to_s
        existing.merge(body).merge(
          'resourceType' => resource_type,
          'meta' => { 'versionId' => version, 'lastUpdated' => call('now_instant') }
        )
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_resource']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['resource'].presence || 'Patient'].first
      end
    },

    # ---- DELETE (DELETE [type]/[id]) --------------------------------------
    delete_resource: {
      title: 'Delete resource',
      subtitle: 'Simulate deleting a FHIR resource',
      description: lambda do |_input, _picklist|
        'Delete a <span class="provider">FHIR resource</span> in ' \
          '<span class="provider">mock Epic on FHIR</span> (simulated)'
      end,
      help: 'SIMULATED WRITE. Returns a FHIR OperationOutcome indicating success. Nothing is ' \
            'actually removed from the embedded dataset.',

      config_fields: [
        { name: 'resource', label: 'Resource type', control_type: 'select',
          pick_list: 'resource_types', optional: false }
      ],

      input_fields: lambda do |_object_definitions|
        [{ name: 'id', label: 'Resource ID', optional: false }]
      end,

      execute: lambda do |_connection, input|
        call('operation_outcome', 'information', 'informational',
             "Successfully deleted #{input['resource']}/#{input['id']} (simulated).")
      end,

      output_fields: lambda do |_object_definitions|
        [
          { name: 'resourceType' },
          { name: 'issue', type: 'array', of: 'object', properties: [
            { name: 'severity' }, { name: 'code' }, { name: 'diagnostics' }
          ] }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        call('operation_outcome', 'information', 'informational', 'Successfully deleted (simulated).')
      end
    }
  },

  # --------------------------------------------------------------------------
  # TRIGGERS  (polling, using FHIR _lastUpdated semantics)
  # --------------------------------------------------------------------------
  triggers: {

    new_resource: {
      title: 'New resource',
      subtitle: 'Triggers when a new FHIR resource appears (mock)',
      description: lambda do |_input, _picklist|
        'New <span class="provider">FHIR resource</span> in ' \
          '<span class="provider">mock Epic on FHIR</span>'
      end,
      help: 'Polls the embedded dataset for resources whose meta.lastUpdated is newer than ' \
            'the last poll (FHIR _lastUpdated semantics). On the first poll all seed resources ' \
            'flow through once, then dedup on id prevents repeats.',

      config_fields: [
        { name: 'resource', label: 'Resource type', control_type: 'select',
          pick_list: 'resource_types', optional: false }
      ],

      poll: lambda do |_connection, input, closure|
        closure ||= {}
        since = closure['since'].presence || '1970-01-01T00:00:00Z'
        resources = call('mock_data')[input['resource']]
                    .select { |r| (r.dig('meta', 'lastUpdated') || '') > since }
                    .sort_by { |r| r.dig('meta', 'lastUpdated') }
        {
          events: resources,
          next_poll: { 'since' => call('now_instant') },
          can_poll_more: false
        }
      end,

      dedup: lambda { |resource| resource['id'] },

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_resource']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['resource'].presence || 'Patient'].first
      end
    },

    new_or_updated_resource: {
      title: 'New or updated resource',
      subtitle: 'Triggers when a FHIR resource is created or updated (mock)',
      description: lambda do |_input, _picklist|
        'New or updated <span class="provider">FHIR resource</span> in ' \
          '<span class="provider">mock Epic on FHIR</span>'
      end,
      help: 'Polls the embedded dataset for resources whose meta.lastUpdated is newer than ' \
            'the last poll. On the first poll all seed resources flow through once; dedup on ' \
            'id@versionId lets a genuinely re-versioned resource fire again.',

      config_fields: [
        { name: 'resource', label: 'Resource type', control_type: 'select',
          pick_list: 'resource_types', optional: false }
      ],

      poll: lambda do |_connection, input, closure|
        closure ||= {}
        since = closure['since'].presence || '1970-01-01T00:00:00Z'
        resources = call('mock_data')[input['resource']]
                    .select { |r| (r.dig('meta', 'lastUpdated') || '') > since }
                    .sort_by { |r| r.dig('meta', 'lastUpdated') }
        {
          events: resources,
          next_poll: { 'since' => call('now_instant') },
          can_poll_more: false
        }
      end,

      dedup: lambda { |resource| "#{resource['id']}@#{resource.dig('meta', 'versionId')}" },

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_resource']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['resource'].presence || 'Patient'].first
      end
    }
  },

  # --------------------------------------------------------------------------
  # METHODS  (reusable logic -- schema, search, id/instant, data)
  # --------------------------------------------------------------------------
  methods: {

    now_instant: lambda do
      Time.now.utc.iso8601
    end,

    # FHIR logical id (UUID-style; valid FHIR id chars).
    generate_fhir_id: lambda do
      hex = ('0'..'9').to_a + ('a'..'f').to_a
      part = ->(n) { (1..n).map { hex.sample }.join }
      "#{part.call(8)}-#{part.call(4)}-#{part.call(4)}-#{part.call(4)}-#{part.call(12)}"
    end,

    # FHIR OperationOutcome builder.
    operation_outcome: lambda do |severity, code, diagnostics|
      {
        'resourceType' => 'OperationOutcome',
        'issue' => [{ 'severity' => severity, 'code' => code, 'diagnostics' => diagnostics }]
      }
    end,

    # Raise a FHIR not-found OperationOutcome (as a JSON error message).
    not_found!: lambda do |resource_type, id|
      error(call('operation_outcome', 'error', 'not-found',
                 "Resource #{resource_type}/#{id} was not found.").to_json)
    end,

    # ------------------------------------------------------------------------
    # resource_schema -- FHIR R4 field definitions per resourceType.
    # Built from shared fragments (CodeableConcept, Reference, etc.) so the
    # dynamic_resource schema matches read output exactly.
    # ------------------------------------------------------------------------
    resource_schema: lambda do |resource|
      coding   = [{ name: 'system' }, { name: 'code' }, { name: 'display' }]
      cc       = lambda do |name, label = nil|
        { name: name, label: label, type: 'object', properties: [
          { name: 'coding', type: 'array', of: 'object', properties: coding },
          { name: 'text' }
        ] }
      end
      cc_arr   = lambda do |name, label = nil|
        { name: name, label: label, type: 'array', of: 'object', properties: [
          { name: 'coding', type: 'array', of: 'object', properties: coding },
          { name: 'text' }
        ] }
      end
      ref      = lambda do |name, label = nil|
        { name: name, label: label, type: 'object',
          properties: [{ name: 'reference' }, { name: 'display' }, { name: 'type' }] }
      end
      ref_arr  = lambda do |name, label = nil|
        { name: name, label: label, type: 'array', of: 'object',
          properties: [{ name: 'reference' }, { name: 'display' }, { name: 'type' }] }
      end
      quantity = lambda do |name, label = nil|
        { name: name, label: label, type: 'object', properties: [
          { name: 'value', type: 'number' }, { name: 'unit' },
          { name: 'system' }, { name: 'code' }
        ] }
      end
      identifier = { name: 'identifier', type: 'array', of: 'object',
                     properties: [{ name: 'use' }, { name: 'system' }, { name: 'value' }] }
      human_name = { name: 'name', type: 'array', of: 'object', properties: [
        { name: 'use' }, { name: 'text' }, { name: 'family' },
        { name: 'given', type: 'array', of: 'string' },
        { name: 'prefix', type: 'array', of: 'string' }
      ] }
      telecom = { name: 'telecom', type: 'array', of: 'object',
                  properties: [{ name: 'system' }, { name: 'value' }, { name: 'use' }] }
      address = { name: 'address', type: 'array', of: 'object', properties: [
        { name: 'use' }, { name: 'line', type: 'array', of: 'string' },
        { name: 'city' }, { name: 'state' }, { name: 'postalCode' }, { name: 'country' },
        { name: 'text' }
      ] }
      period = { name: 'period', type: 'object',
                 properties: [{ name: 'start', type: 'date_time' }, { name: 'end', type: 'date_time' }] }
      meta = { name: 'meta', type: 'object',
               properties: [{ name: 'versionId' }, { name: 'lastUpdated', type: 'date_time' }] }
      base = [{ name: 'resourceType', label: 'Resource type' }, { name: 'id' }, meta]

      schemas = {
        'Patient' => base + [
          identifier,
          { name: 'active', type: 'boolean' },
          human_name,
          telecom,
          { name: 'gender' },
          { name: 'birthDate', type: 'date' },
          address,
          cc.call('maritalStatus', 'Marital status'),
          ref.call('managingOrganization', 'Managing organization'),
          ref_arr.call('generalPractitioner', 'General practitioner')
        ],
        'Practitioner' => base + [
          identifier,
          { name: 'active', type: 'boolean' },
          human_name,
          telecom,
          { name: 'gender' },
          { name: 'qualification', type: 'array', of: 'object', properties: [
            cc.call('code', 'Qualification'), ref.call('issuer', 'Issuer')
          ] }
        ],
        'Organization' => base + [
          identifier,
          { name: 'active', type: 'boolean' },
          cc_arr.call('type', 'Type'),
          { name: 'name' },
          telecom,
          address
        ],
        'Coverage' => base + [
          identifier,
          { name: 'status' },
          cc.call('type', 'Type'),
          ref.call('subscriber', 'Subscriber (Patient)'),
          { name: 'subscriberId' },
          ref.call('beneficiary', 'Beneficiary (Patient)'),
          cc.call('relationship', 'Relationship'),
          period,
          ref_arr.call('payor', 'Payor (Organization)'),
          { name: 'class', type: 'array', of: 'object', properties: [
            cc.call('type', 'Type'), { name: 'value' }, { name: 'name' } ] }
        ],
        'Claim' => base + [
          identifier,
          { name: 'status' },
          cc.call('type', 'Type'),
          { name: 'use' },
          ref.call('patient', 'Patient'),
          { name: 'created', type: 'date_time' },
          ref.call('provider', 'Provider'),
          cc.call('priority', 'Priority'),
          { name: 'insurance', type: 'array', of: 'object', properties: [
            { name: 'sequence', type: 'integer' }, { name: 'focal', type: 'boolean' }, ref.call('coverage', 'Coverage') ] },
          { name: 'diagnosis', type: 'array', of: 'object', properties: [
            { name: 'sequence', type: 'integer' }, cc.call('diagnosisCodeableConcept', 'Diagnosis') ] },
          { name: 'item', type: 'array', of: 'object', properties: [
            { name: 'sequence', type: 'integer' }, cc.call('productOrService', 'Product/Service'),
            quantity.call('quantity', 'Quantity'),
            { name: 'unitPrice', type: 'object', properties: [{ name: 'value', type: 'number' }, { name: 'currency' }] },
            { name: 'net', type: 'object', properties: [{ name: 'value', type: 'number' }, { name: 'currency' }] } ] },
          { name: 'total', type: 'object', properties: [{ name: 'value', type: 'number' }, { name: 'currency' }] }
        ],
        'ExplanationOfBenefit' => base + [
          identifier,
          { name: 'status' },
          cc.call('type', 'Type'),
          { name: 'use' },
          ref.call('patient', 'Patient'),
          { name: 'created', type: 'date_time' },
          ref.call('insurer', 'Insurer (Organization)'),
          ref.call('provider', 'Provider'),
          ref.call('claim', 'Claim'),
          { name: 'outcome' },
          { name: 'item', type: 'array', of: 'object', properties: [
            { name: 'sequence', type: 'integer' }, cc.call('productOrService', 'Product/Service'),
            { name: 'adjudication', type: 'array', of: 'object', properties: [
              cc.call('category', 'Category'),
              { name: 'amount', type: 'object', properties: [{ name: 'value', type: 'number' }, { name: 'currency' }] } ] } ] },
          { name: 'total', type: 'array', of: 'object', properties: [
            cc.call('category', 'Category'),
            { name: 'amount', type: 'object', properties: [{ name: 'value', type: 'number' }, { name: 'currency' }] } ] },
          { name: 'payment', type: 'object', properties: [
            cc.call('type', 'Type'),
            { name: 'amount', type: 'object', properties: [{ name: 'value', type: 'number' }, { name: 'currency' }] },
            { name: 'date', type: 'date' } ] }
        ],
        'Encounter' => base + [
          identifier,
          { name: 'status' },
          { name: 'class', type: 'object', properties: coding },
          cc_arr.call('type', 'Type'),
          ref.call('subject', 'Subject (Patient)'),
          { name: 'participant', type: 'array', of: 'object', properties: [
            cc_arr.call('type', 'Type'), ref.call('individual', 'Individual (Practitioner)')
          ] },
          period,
          cc_arr.call('reasonCode', 'Reason'),
          ref.call('serviceProvider', 'Service provider (Organization)')
        ],
        'Condition' => base + [
          identifier,
          cc.call('clinicalStatus', 'Clinical status'),
          cc.call('verificationStatus', 'Verification status'),
          cc_arr.call('category', 'Category'),
          cc.call('severity', 'Severity'),
          cc.call('code', 'Code (ICD-10/SNOMED)'),
          ref.call('subject', 'Subject (Patient)'),
          ref.call('encounter', 'Encounter'),
          { name: 'onsetDateTime', type: 'date_time' },
          { name: 'recordedDate', type: 'date_time' }
        ]
      }
      schemas[resource] || base
    end,

    # find_resources -- read path: fetch a resourceType's seed data and filter.
    find_resources: lambda do |resource_type, params|
      resources = call('mock_data')[resource_type]
      error("Unknown resource type: #{resource_type}") if resources.nil?
      params = Array.wrap(params)
      return resources if params.empty?

      resources.select do |r|
        params.all? { |p| call('match_param', resource_type, p['param'], p['value'], r) }
      end
    end,

    # build_bundle -- wrap matches in a FHIR Bundle (type: searchset).
    build_bundle: lambda do |resource_type, resources|
      {
        'resourceType' => 'Bundle',
        'type' => 'searchset',
        'total' => resources.length,
        'link' => [{ 'relation' => 'self', 'url' => "#{resource_type}?_mock=true" }],
        'entry' => resources.map do |r|
          {
            'fullUrl' => "urn:mock:#{resource_type}/#{r['id']}",
            'resource' => r,
            'search' => { 'mode' => 'match' }
          }
        end
      }
    end,

    # ------------------------------------------------------------------------
    # match_param -- "FHIR-search-lite": evaluate one search param against a
    # resource. String params match case-insensitive substring; token params
    # match exact; reference params accept "Type/id" or bare "id"; date params
    # support FHIR prefixes (eq/ge/gt/le/lt). Falls back to a top-level field.
    # ------------------------------------------------------------------------
    match_param: lambda do |_resource_type, param, value, r|
      v = value.to_s
      case param.to_s
      when '_id'
        r['id'].to_s == v
      when '_lastUpdated'
        call('date_match', r.dig('meta', 'lastUpdated'), v)
      when 'identifier'
        Array.wrap(r['identifier']).any? { |i| i['value'].to_s == v }
      when 'name'
        Array.wrap(r['name']).any? do |n|
          [n['text'], n['family'], *Array.wrap(n['given'])].compact
                                                            .any? { |s| s.to_s.downcase.include?(v.downcase) }
        end
      when 'family'
        Array.wrap(r['name']).any? { |n| n['family'].to_s.downcase.include?(v.downcase) }
      when 'given'
        Array.wrap(r['name']).any? { |n| Array.wrap(n['given']).any? { |g| g.to_s.downcase.include?(v.downcase) } }
      when 'gender'
        r['gender'].to_s.casecmp?(v)
      when 'birthdate'
        call('date_match', r['birthDate'], v)
      when 'status'
        r['status'].to_s.casecmp?(v)
      when 'clinical-status'
        call('token_in_cc', r['clinicalStatus'], v)
      when 'intent'
        r['intent'].to_s.casecmp?(v)
      when 'code'
        call('token_in_cc', r['code'], v) || call('token_in_cc', r['medicationCodeableConcept'], v)
      when 'category'
        Array.wrap(r['category']).any? { |c| call('token_in_cc', c, v) }
      when 'patient', 'subject'
        call('ref_match', r['subject'] || r['patient'] || r['beneficiary'], 'Patient', v)
      when 'encounter'
        call('ref_match', r['encounter'], 'Encounter', v)
      when 'payor', 'insurer', 'organization'
        [r['managingOrganization'], r['serviceProvider'], r['insurer'], *Array.wrap(r['payor'])].compact
          .any? { |rf| call('ref_match', rf, 'Organization', v) }
      when 'date'
        actual = r['effectiveDateTime'] || r['start'] || r.dig('period', 'start') ||
                 r['authoredOn'] || r['onsetDateTime'] || r['created']
        call('date_match', actual, v)
      when 'authoredon'
        call('date_match', r['authoredOn'], v)
      else
        # Generic fallback: exact match on a top-level string field.
        r[param].is_a?(String) && r[param].casecmp?(v)
      end
    end,

    # token match against a CodeableConcept (code or text).
    token_in_cc: lambda do |cc, value|
      return false if cc.nil?

      v = value.to_s
      Array.wrap(cc['coding']).any? { |c| c['code'].to_s == v } ||
        cc['text'].to_s.casecmp?(v)
    end,

    # reference match; accepts "Type/id" or bare "id".
    ref_match: lambda do |reference, type, value|
      return false if reference.nil?

      actual = reference['reference'].to_s
      actual == value.to_s || actual == "#{type}/#{value}"
    end,

    # FHIR date param match with optional prefix (eq/ge/gt/le/lt). Compares on
    # the shared leading substring length so a date param matches a dateTime.
    date_match: lambda do |actual, value|
      return false if actual.nil?

      m = value.to_s.match(/\A(eq|ne|ge|gt|le|lt)?(.+)\z/)
      prefix = m[1] || 'eq'
      target = m[2]
      a = actual.to_s[0, target.length]
      case prefix
      when 'eq' then a == target
      when 'ne' then a != target
      when 'ge' then a >= target
      when 'gt' then a > target
      when 'le' then a <= target
      when 'lt' then a < target
      end
    end,

    # fhir_search -- parse a raw FHIR query "Type?a=b&c=d" into params.
    fhir_search: lambda do |query|
      q = query.to_s.strip
      resource_type, _, rest = q.partition('?')
      params = rest.split('&').reject(&:empty?).map do |pair|
        k, _, val = pair.partition('=')
        { 'param' => k.strip, 'value' => CGI.unescape(val.to_s.strip) }
      end
      { 'resourceType' => resource_type.strip, 'params' => params }
    end,

    # ========================================================================
    # mock_data -- the ENTIRE embedded payer dataset (FHIR R4). Internally
    # consistent: Coverage/Claim/ExplanationOfBenefit reference real Patients
    # (members), Organizations (payer + provider), Practitioners, Encounters,
    # and Conditions. A believable health plan: BlueRiver Health Plan.
    # ========================================================================
    mock_data: lambda do
      org_blueriver = 'org-blueriver'
      org_cvhs      = 'org-cvhs'
      prac_mercer   = 'prac-mercer'
      prac_raman    = 'prac-raman'
      pat_reynolds  = 'pat-mreynolds'
      pat_calderon  = 'pat-jcalderon'
      pat_nguyen    = 'pat-snguyen'

      {
        'Organization' => [
          { 'resourceType' => 'Organization', 'id' => org_blueriver,
            'meta' => { 'versionId' => '3', 'lastUpdated' => '2026-04-01T12:00:00Z' },
            'identifier' => [{ 'use' => 'official',
                               'system' => 'http://hl7.org/fhir/sid/us-npi', 'value' => '1659384122' }],
            'active' => true,
            'type' => [{ 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/organization-type',
                                        'code' => 'pay', 'display' => 'Payer' }], 'text' => 'Health Plan' }],
            'name' => 'BlueRiver Health Plan',
            'telecom' => [{ 'system' => 'phone', 'value' => '+1-617-555-0300', 'use' => 'work' }],
            'address' => [{ 'use' => 'work', 'line' => ['100 Riverside Plaza'], 'city' => 'Boston',
                            'state' => 'MA', 'postalCode' => '02210', 'country' => 'US',
                            'text' => '100 Riverside Plaza, Boston, MA 02210' }] },
          { 'resourceType' => 'Organization', 'id' => org_cvhs,
            'meta' => { 'versionId' => '2', 'lastUpdated' => '2026-04-02T12:00:00Z' },
            'identifier' => [{ 'use' => 'official',
                               'system' => 'http://hl7.org/fhir/sid/us-npi', 'value' => '1457382910' }],
            'active' => true,
            'type' => [{ 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/organization-type',
                                        'code' => 'prov', 'display' => 'Healthcare Provider' }], 'text' => 'Health System' }],
            'name' => 'Cedar Valley Health System',
            'telecom' => [{ 'system' => 'phone', 'value' => '+1-617-555-0100', 'use' => 'work' }],
            'address' => [{ 'use' => 'work', 'line' => ['400 Cedar Valley Way'], 'city' => 'Boston',
                            'state' => 'MA', 'postalCode' => '02115', 'country' => 'US',
                            'text' => '400 Cedar Valley Way, Boston, MA 02115' }] }
        ],

        'Practitioner' => [
          { 'resourceType' => 'Practitioner', 'id' => prac_mercer,
            'meta' => { 'versionId' => '4', 'lastUpdated' => '2026-04-10T09:00:00Z' },
            'identifier' => [{ 'use' => 'official', 'system' => 'http://hl7.org/fhir/sid/us-npi', 'value' => '1730174655' }],
            'active' => true,
            'name' => [{ 'use' => 'official', 'text' => 'Alan Mercer, MD', 'family' => 'Mercer',
                         'given' => ['Alan'], 'prefix' => ['Dr.'] }],
            'telecom' => [{ 'system' => 'email', 'value' => 'amercer@cedarvalley.example.com', 'use' => 'work' }],
            'gender' => 'male',
            'qualification' => [{ 'code' => { 'coding' => [{ 'system' => 'http://nucc.org/provider-taxonomy',
                                                             'code' => '207RC0000X', 'display' => 'Cardiovascular Disease' }],
                                              'text' => 'Cardiologist' } }] },
          { 'resourceType' => 'Practitioner', 'id' => prac_raman,
            'meta' => { 'versionId' => '3', 'lastUpdated' => '2026-04-11T09:00:00Z' },
            'identifier' => [{ 'use' => 'official', 'system' => 'http://hl7.org/fhir/sid/us-npi', 'value' => '1841285766' }],
            'active' => true,
            'name' => [{ 'use' => 'official', 'text' => 'Priya Raman, MD', 'family' => 'Raman',
                         'given' => ['Priya'], 'prefix' => ['Dr.'] }],
            'telecom' => [{ 'system' => 'email', 'value' => 'praman@cedarvalley.example.com', 'use' => 'work' }],
            'gender' => 'female',
            'qualification' => [{ 'code' => { 'coding' => [{ 'system' => 'http://nucc.org/provider-taxonomy',
                                                             'code' => '207Q00000X', 'display' => 'Family Medicine' }],
                                              'text' => 'Family Medicine Physician' } }] }
        ],

        'Patient' => [
          { 'resourceType' => 'Patient', 'id' => pat_reynolds,
            'meta' => { 'versionId' => '5', 'lastUpdated' => '2026-05-20T14:30:00Z' },
            'identifier' => [{ 'use' => 'usual', 'system' => 'http://blueriverhealth.example.com/member-id', 'value' => 'BRH-100482' }],
            'active' => true,
            'name' => [{ 'use' => 'official', 'text' => 'Martha Reynolds', 'family' => 'Reynolds', 'given' => ['Martha', 'J'] }],
            'telecom' => [{ 'system' => 'phone', 'value' => '+1-617-555-0188', 'use' => 'mobile' }],
            'gender' => 'female', 'birthDate' => '1957-03-12',
            'address' => [{ 'use' => 'home', 'line' => ['18 Maple Court'], 'city' => 'Cambridge',
                            'state' => 'MA', 'postalCode' => '02139', 'country' => 'US' }] },
          { 'resourceType' => 'Patient', 'id' => pat_calderon,
            'meta' => { 'versionId' => '3', 'lastUpdated' => '2026-05-22T10:15:00Z' },
            'identifier' => [{ 'use' => 'usual', 'system' => 'http://blueriverhealth.example.com/member-id', 'value' => 'BRH-100513' }],
            'active' => true,
            'name' => [{ 'use' => 'official', 'text' => 'James Calderon', 'family' => 'Calderon', 'given' => ['James'] }],
            'telecom' => [{ 'system' => 'phone', 'value' => '+1-617-555-0211', 'use' => 'mobile' }],
            'gender' => 'male', 'birthDate' => '1972-09-03',
            'address' => [{ 'use' => 'home', 'line' => ['77 Birchwood Ave'], 'city' => 'Somerville',
                            'state' => 'MA', 'postalCode' => '02143', 'country' => 'US' }] },
          { 'resourceType' => 'Patient', 'id' => pat_nguyen,
            'meta' => { 'versionId' => '2', 'lastUpdated' => '2026-06-01T08:45:00Z' },
            'identifier' => [{ 'use' => 'usual', 'system' => 'http://blueriverhealth.example.com/member-id', 'value' => 'BRH-100547' }],
            'active' => true,
            'name' => [{ 'use' => 'official', 'text' => 'Sofia Nguyen', 'family' => 'Nguyen', 'given' => ['Sofia'] }],
            'telecom' => [{ 'system' => 'phone', 'value' => '+1-617-555-0233', 'use' => 'mobile' }],
            'gender' => 'female', 'birthDate' => '1989-11-27',
            'address' => [{ 'use' => 'home', 'line' => ['5 Harbor St', 'Apt 12'], 'city' => 'Boston',
                            'state' => 'MA', 'postalCode' => '02128', 'country' => 'US' }] }
        ],

        'Coverage' => [
          { 'resourceType' => 'Coverage', 'id' => 'cov-reynolds',
            'meta' => { 'versionId' => '2', 'lastUpdated' => '2026-05-20T14:30:00Z' },
            'identifier' => [{ 'use' => 'official', 'system' => 'http://blueriverhealth.example.com/coverage-id', 'value' => 'COV-100482' }],
            'status' => 'active',
            'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
                                       'code' => 'EHCPOL', 'display' => 'extended healthcare' }], 'text' => 'Extended healthcare' },
            'subscriber' => { 'reference' => "Patient/#{pat_reynolds}", 'display' => 'Martha Reynolds' },
            'subscriberId' => 'BRH-100482',
            'beneficiary' => { 'reference' => "Patient/#{pat_reynolds}", 'display' => 'Martha Reynolds' },
            'relationship' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/subscriber-relationship',
                                               'code' => 'self', 'display' => 'Self' }], 'text' => 'Self' },
            'period' => { 'start' => '2026-01-01T00:00:00Z', 'end' => '2026-12-31T23:59:59Z' },
            'payor' => [{ 'reference' => "Organization/#{org_blueriver}", 'display' => 'BlueRiver Health Plan' }],
            'class' => [
              { 'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/coverage-class',
                                           'code' => 'plan', 'display' => 'Plan' }] }, 'value' => 'BRH-PPO-2026', 'name' => 'BlueRiver PPO 2026' },
              { 'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/coverage-class',
                                           'code' => 'group', 'display' => 'Group' }] }, 'value' => 'GRP-CVHS-001', 'name' => 'Cedar Valley Employer Group' }
            ] },
          { 'resourceType' => 'Coverage', 'id' => 'cov-calderon',
            'meta' => { 'versionId' => '2', 'lastUpdated' => '2026-05-22T10:15:00Z' },
            'identifier' => [{ 'use' => 'official', 'system' => 'http://blueriverhealth.example.com/coverage-id', 'value' => 'COV-100513' }],
            'status' => 'active',
            'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
                                       'code' => 'EHCPOL', 'display' => 'extended healthcare' }], 'text' => 'Extended healthcare' },
            'subscriber' => { 'reference' => "Patient/#{pat_calderon}", 'display' => 'James Calderon' },
            'subscriberId' => 'BRH-100513',
            'beneficiary' => { 'reference' => "Patient/#{pat_calderon}", 'display' => 'James Calderon' },
            'relationship' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/subscriber-relationship',
                                               'code' => 'self', 'display' => 'Self' }], 'text' => 'Self' },
            'period' => { 'start' => '2026-01-01T00:00:00Z', 'end' => '2026-12-31T23:59:59Z' },
            'payor' => [{ 'reference' => "Organization/#{org_blueriver}", 'display' => 'BlueRiver Health Plan' }],
            'class' => [
              { 'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/coverage-class',
                                           'code' => 'plan', 'display' => 'Plan' }] }, 'value' => 'BRH-PPO-2026', 'name' => 'BlueRiver PPO 2026' },
              { 'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/coverage-class',
                                           'code' => 'group', 'display' => 'Group' }] }, 'value' => 'GRP-CVHS-001', 'name' => 'Cedar Valley Employer Group' }
            ] },
          { 'resourceType' => 'Coverage', 'id' => 'cov-nguyen',
            'meta' => { 'versionId' => '2', 'lastUpdated' => '2026-06-01T08:45:00Z' },
            'identifier' => [{ 'use' => 'official', 'system' => 'http://blueriverhealth.example.com/coverage-id', 'value' => 'COV-100547' }],
            'status' => 'active',
            'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
                                       'code' => 'EHCPOL', 'display' => 'extended healthcare' }], 'text' => 'Extended healthcare' },
            'subscriber' => { 'reference' => "Patient/#{pat_nguyen}", 'display' => 'Sofia Nguyen' },
            'subscriberId' => 'BRH-100547',
            'beneficiary' => { 'reference' => "Patient/#{pat_nguyen}", 'display' => 'Sofia Nguyen' },
            'relationship' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/subscriber-relationship',
                                               'code' => 'self', 'display' => 'Self' }], 'text' => 'Self' },
            'period' => { 'start' => '2026-01-01T00:00:00Z', 'end' => '2026-12-31T23:59:59Z' },
            'payor' => [{ 'reference' => "Organization/#{org_blueriver}", 'display' => 'BlueRiver Health Plan' }],
            'class' => [
              { 'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/coverage-class',
                                           'code' => 'plan', 'display' => 'Plan' }] }, 'value' => 'BRH-PPO-2026', 'name' => 'BlueRiver PPO 2026' },
              { 'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/coverage-class',
                                           'code' => 'group', 'display' => 'Group' }] }, 'value' => 'GRP-CVHS-001', 'name' => 'Cedar Valley Employer Group' }
            ] }
        ],

        'Claim' => [
          { 'resourceType' => 'Claim', 'id' => 'claim-reynolds-001',
            'meta' => { 'versionId' => '1', 'lastUpdated' => '2026-05-21T09:00:00Z' },
            'identifier' => [{ 'use' => 'official', 'system' => 'http://blueriverhealth.example.com/claim-id', 'value' => 'CLM-2026-000482' }],
            'status' => 'active',
            'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/claim-type',
                                       'code' => 'professional', 'display' => 'Professional' }], 'text' => 'Professional' },
            'use' => 'claim',
            'patient' => { 'reference' => "Patient/#{pat_reynolds}", 'display' => 'Martha Reynolds' },
            'created' => '2026-05-21T09:00:00Z',
            'provider' => { 'reference' => "Organization/#{org_cvhs}", 'display' => 'Cedar Valley Health System' },
            'priority' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/processpriority',
                                           'code' => 'normal', 'display' => 'Normal' }], 'text' => 'Normal' },
            'insurance' => [{ 'sequence' => 1, 'focal' => true,
                              'coverage' => { 'reference' => 'Coverage/cov-reynolds', 'display' => 'BlueRiver PPO 2026' } }],
            'diagnosis' => [{ 'sequence' => 1,
                              'diagnosisCodeableConcept' => { 'coding' => [{ 'system' => 'http://hl7.org/fhir/sid/icd-10-cm',
                                                                            'code' => 'I10', 'display' => 'Essential (primary) hypertension' }],
                                                             'text' => 'Essential hypertension' } }],
            'item' => [{ 'sequence' => 1,
                         'productOrService' => { 'coding' => [{ 'system' => 'http://www.ama-assn.org/go/cpt',
                                                               'code' => '99214', 'display' => 'Office/outpatient visit, established patient' }],
                                                'text' => 'Office visit, established patient' },
                         'quantity' => { 'value' => 1 },
                         'unitPrice' => { 'value' => 245.00, 'currency' => 'USD' },
                         'net' => { 'value' => 245.00, 'currency' => 'USD' } }],
            'total' => { 'value' => 245.00, 'currency' => 'USD' } },
          { 'resourceType' => 'Claim', 'id' => 'claim-calderon-001',
            'meta' => { 'versionId' => '1', 'lastUpdated' => '2026-05-23T09:00:00Z' },
            'identifier' => [{ 'use' => 'official', 'system' => 'http://blueriverhealth.example.com/claim-id', 'value' => 'CLM-2026-000513' }],
            'status' => 'active',
            'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/claim-type',
                                       'code' => 'professional', 'display' => 'Professional' }], 'text' => 'Professional' },
            'use' => 'claim',
            'patient' => { 'reference' => "Patient/#{pat_calderon}", 'display' => 'James Calderon' },
            'created' => '2026-05-23T09:00:00Z',
            'provider' => { 'reference' => "Organization/#{org_cvhs}", 'display' => 'Cedar Valley Health System' },
            'priority' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/processpriority',
                                           'code' => 'normal', 'display' => 'Normal' }], 'text' => 'Normal' },
            'insurance' => [{ 'sequence' => 1, 'focal' => true,
                              'coverage' => { 'reference' => 'Coverage/cov-calderon', 'display' => 'BlueRiver PPO 2026' } }],
            'diagnosis' => [{ 'sequence' => 1,
                              'diagnosisCodeableConcept' => { 'coding' => [{ 'system' => 'http://hl7.org/fhir/sid/icd-10-cm',
                                                                            'code' => 'E11.9', 'display' => 'Type 2 diabetes mellitus without complications' }],
                                                             'text' => 'Type 2 diabetes mellitus' } }],
            'item' => [{ 'sequence' => 1,
                         'productOrService' => { 'coding' => [{ 'system' => 'http://www.ama-assn.org/go/cpt',
                                                               'code' => '99214', 'display' => 'Office/outpatient visit, established patient' }],
                                                'text' => 'Office visit, established patient' },
                         'quantity' => { 'value' => 1 },
                         'unitPrice' => { 'value' => 320.00, 'currency' => 'USD' },
                         'net' => { 'value' => 320.00, 'currency' => 'USD' } }],
            'total' => { 'value' => 320.00, 'currency' => 'USD' } },
          { 'resourceType' => 'Claim', 'id' => 'claim-nguyen-001',
            'meta' => { 'versionId' => '1', 'lastUpdated' => '2026-06-02T09:00:00Z' },
            'identifier' => [{ 'use' => 'official', 'system' => 'http://blueriverhealth.example.com/claim-id', 'value' => 'CLM-2026-000547' }],
            'status' => 'active',
            'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/claim-type',
                                       'code' => 'professional', 'display' => 'Professional' }], 'text' => 'Professional' },
            'use' => 'claim',
            'patient' => { 'reference' => "Patient/#{pat_nguyen}", 'display' => 'Sofia Nguyen' },
            'created' => '2026-06-02T09:00:00Z',
            'provider' => { 'reference' => "Organization/#{org_cvhs}", 'display' => 'Cedar Valley Health System' },
            'priority' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/processpriority',
                                           'code' => 'normal', 'display' => 'Normal' }], 'text' => 'Normal' },
            'insurance' => [{ 'sequence' => 1, 'focal' => true,
                              'coverage' => { 'reference' => 'Coverage/cov-nguyen', 'display' => 'BlueRiver PPO 2026' } }],
            'diagnosis' => [{ 'sequence' => 1,
                              'diagnosisCodeableConcept' => { 'coding' => [{ 'system' => 'http://hl7.org/fhir/sid/icd-10-cm',
                                                                            'code' => 'Z00.00', 'display' => 'Encounter for general adult medical examination without abnormal findings' }],
                                                             'text' => 'General adult medical exam' } }],
            'item' => [{ 'sequence' => 1,
                         'productOrService' => { 'coding' => [{ 'system' => 'http://www.ama-assn.org/go/cpt',
                                                               'code' => '99395', 'display' => 'Periodic preventive medicine, established patient, 18-39 years' }],
                                                'text' => 'Preventive visit, established patient' },
                         'quantity' => { 'value' => 1 },
                         'unitPrice' => { 'value' => 180.00, 'currency' => 'USD' },
                         'net' => { 'value' => 180.00, 'currency' => 'USD' } }],
            'total' => { 'value' => 180.00, 'currency' => 'USD' } }
        ],

        'ExplanationOfBenefit' => [
          { 'resourceType' => 'ExplanationOfBenefit', 'id' => 'eob-reynolds-001',
            'meta' => { 'versionId' => '1', 'lastUpdated' => '2026-05-28T11:00:00Z' },
            'identifier' => [{ 'use' => 'official', 'system' => 'http://blueriverhealth.example.com/eob-id', 'value' => 'EOB-2026-000482' }],
            'status' => 'active',
            'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/claim-type',
                                       'code' => 'professional', 'display' => 'Professional' }], 'text' => 'Professional' },
            'use' => 'claim',
            'patient' => { 'reference' => "Patient/#{pat_reynolds}", 'display' => 'Martha Reynolds' },
            'created' => '2026-05-28T11:00:00Z',
            'insurer' => { 'reference' => "Organization/#{org_blueriver}", 'display' => 'BlueRiver Health Plan' },
            'provider' => { 'reference' => "Organization/#{org_cvhs}", 'display' => 'Cedar Valley Health System' },
            'claim' => { 'reference' => 'Claim/claim-reynolds-001', 'display' => 'CLM-2026-000482' },
            'outcome' => 'complete',
            'item' => [{ 'sequence' => 1,
                         'productOrService' => { 'coding' => [{ 'system' => 'http://www.ama-assn.org/go/cpt',
                                                               'code' => '99214', 'display' => 'Office/outpatient visit, established patient' }],
                                                'text' => 'Office visit, established patient' },
                         'adjudication' => [
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'submitted', 'display' => 'Submitted Amount' }] },
                             'amount' => { 'value' => 245.00, 'currency' => 'USD' } },
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'eligible', 'display' => 'Eligible Amount' }] },
                             'amount' => { 'value' => 200.00, 'currency' => 'USD' } },
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'benefit', 'display' => 'Benefit Amount' }] },
                             'amount' => { 'value' => 170.00, 'currency' => 'USD' } },
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'copay', 'display' => 'CoPay' }] },
                             'amount' => { 'value' => 30.00, 'currency' => 'USD' } }
                         ] }],
            'total' => [
              { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'submitted', 'display' => 'Submitted Amount' }] },
                'amount' => { 'value' => 245.00, 'currency' => 'USD' } },
              { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'benefit', 'display' => 'Benefit Amount' }] },
                'amount' => { 'value' => 170.00, 'currency' => 'USD' } }
            ],
            'payment' => { 'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/ex-paymenttype', 'code' => 'complete', 'display' => 'Complete' }] },
                           'amount' => { 'value' => 170.00, 'currency' => 'USD' }, 'date' => '2026-05-29' } },
          { 'resourceType' => 'ExplanationOfBenefit', 'id' => 'eob-calderon-001',
            'meta' => { 'versionId' => '1', 'lastUpdated' => '2026-05-30T11:00:00Z' },
            'identifier' => [{ 'use' => 'official', 'system' => 'http://blueriverhealth.example.com/eob-id', 'value' => 'EOB-2026-000513' }],
            'status' => 'active',
            'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/claim-type',
                                       'code' => 'professional', 'display' => 'Professional' }], 'text' => 'Professional' },
            'use' => 'claim',
            'patient' => { 'reference' => "Patient/#{pat_calderon}", 'display' => 'James Calderon' },
            'created' => '2026-05-30T11:00:00Z',
            'insurer' => { 'reference' => "Organization/#{org_blueriver}", 'display' => 'BlueRiver Health Plan' },
            'provider' => { 'reference' => "Organization/#{org_cvhs}", 'display' => 'Cedar Valley Health System' },
            'claim' => { 'reference' => 'Claim/claim-calderon-001', 'display' => 'CLM-2026-000513' },
            'outcome' => 'complete',
            'item' => [{ 'sequence' => 1,
                         'productOrService' => { 'coding' => [{ 'system' => 'http://www.ama-assn.org/go/cpt',
                                                               'code' => '99214', 'display' => 'Office/outpatient visit, established patient' }],
                                                'text' => 'Office visit, established patient' },
                         'adjudication' => [
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'submitted', 'display' => 'Submitted Amount' }] },
                             'amount' => { 'value' => 320.00, 'currency' => 'USD' } },
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'eligible', 'display' => 'Eligible Amount' }] },
                             'amount' => { 'value' => 260.00, 'currency' => 'USD' } },
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'benefit', 'display' => 'Benefit Amount' }] },
                             'amount' => { 'value' => 230.00, 'currency' => 'USD' } },
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'copay', 'display' => 'CoPay' }] },
                             'amount' => { 'value' => 30.00, 'currency' => 'USD' } }
                         ] }],
            'total' => [
              { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'submitted', 'display' => 'Submitted Amount' }] },
                'amount' => { 'value' => 320.00, 'currency' => 'USD' } },
              { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'benefit', 'display' => 'Benefit Amount' }] },
                'amount' => { 'value' => 230.00, 'currency' => 'USD' } }
            ],
            'payment' => { 'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/ex-paymenttype', 'code' => 'complete', 'display' => 'Complete' }] },
                           'amount' => { 'value' => 230.00, 'currency' => 'USD' }, 'date' => '2026-05-31' } },
          { 'resourceType' => 'ExplanationOfBenefit', 'id' => 'eob-nguyen-001',
            'meta' => { 'versionId' => '1', 'lastUpdated' => '2026-06-08T11:00:00Z' },
            'identifier' => [{ 'use' => 'official', 'system' => 'http://blueriverhealth.example.com/eob-id', 'value' => 'EOB-2026-000547' }],
            'status' => 'active',
            'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/claim-type',
                                       'code' => 'professional', 'display' => 'Professional' }], 'text' => 'Professional' },
            'use' => 'claim',
            'patient' => { 'reference' => "Patient/#{pat_nguyen}", 'display' => 'Sofia Nguyen' },
            'created' => '2026-06-08T11:00:00Z',
            'insurer' => { 'reference' => "Organization/#{org_blueriver}", 'display' => 'BlueRiver Health Plan' },
            'provider' => { 'reference' => "Organization/#{org_cvhs}", 'display' => 'Cedar Valley Health System' },
            'claim' => { 'reference' => 'Claim/claim-nguyen-001', 'display' => 'CLM-2026-000547' },
            'outcome' => 'complete',
            'item' => [{ 'sequence' => 1,
                         'productOrService' => { 'coding' => [{ 'system' => 'http://www.ama-assn.org/go/cpt',
                                                               'code' => '99395', 'display' => 'Periodic preventive medicine, established patient, 18-39 years' }],
                                                'text' => 'Preventive visit, established patient' },
                         'adjudication' => [
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'submitted', 'display' => 'Submitted Amount' }] },
                             'amount' => { 'value' => 180.00, 'currency' => 'USD' } },
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'eligible', 'display' => 'Eligible Amount' }] },
                             'amount' => { 'value' => 180.00, 'currency' => 'USD' } },
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'benefit', 'display' => 'Benefit Amount' }] },
                             'amount' => { 'value' => 180.00, 'currency' => 'USD' } },
                           { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'copay', 'display' => 'CoPay' }] },
                             'amount' => { 'value' => 0.00, 'currency' => 'USD' } }
                         ] }],
            'total' => [
              { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'submitted', 'display' => 'Submitted Amount' }] },
                'amount' => { 'value' => 180.00, 'currency' => 'USD' } },
              { 'category' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'benefit', 'display' => 'Benefit Amount' }] },
                'amount' => { 'value' => 180.00, 'currency' => 'USD' } }
            ],
            'payment' => { 'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/ex-paymenttype', 'code' => 'complete', 'display' => 'Complete' }] },
                           'amount' => { 'value' => 180.00, 'currency' => 'USD' }, 'date' => '2026-06-09' } }
        ],

        'Encounter' => [
          { 'resourceType' => 'Encounter', 'id' => 'enc-reynolds-001',
            'meta' => { 'versionId' => '2', 'lastUpdated' => '2026-05-20T14:35:00Z' },
            'status' => 'finished',
            'class' => { 'system' => 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'code' => 'AMB', 'display' => 'ambulatory' },
            'type' => [{ 'coding' => [{ 'system' => 'http://snomed.info/sct', 'code' => '185349003',
                                        'display' => 'Encounter for check up' }], 'text' => 'Office Visit' }],
            'subject' => { 'reference' => "Patient/#{pat_reynolds}", 'display' => 'Martha Reynolds' },
            'participant' => [{ 'type' => [{ 'text' => 'attending' }],
                               'individual' => { 'reference' => "Practitioner/#{prac_mercer}", 'display' => 'Alan Mercer, MD' } }],
            'period' => { 'start' => '2026-05-20T14:00:00Z', 'end' => '2026-05-20T14:35:00Z' },
            'reasonCode' => [{ 'coding' => [{ 'system' => 'http://snomed.info/sct', 'code' => '38341003',
                                              'display' => 'Hypertensive disorder' }], 'text' => 'Hypertension follow-up' }],
            'serviceProvider' => { 'reference' => "Organization/#{org_cvhs}", 'display' => 'Cedar Valley Health System' } },
          { 'resourceType' => 'Encounter', 'id' => 'enc-calderon-001',
            'meta' => { 'versionId' => '1', 'lastUpdated' => '2026-05-22T10:20:00Z' },
            'status' => 'finished',
            'class' => { 'system' => 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'code' => 'AMB', 'display' => 'ambulatory' },
            'type' => [{ 'coding' => [{ 'system' => 'http://snomed.info/sct', 'code' => '185349003',
                                        'display' => 'Encounter for check up' }], 'text' => 'Office Visit' }],
            'subject' => { 'reference' => "Patient/#{pat_calderon}", 'display' => 'James Calderon' },
            'participant' => [{ 'type' => [{ 'text' => 'attending' }],
                               'individual' => { 'reference' => "Practitioner/#{prac_raman}", 'display' => 'Priya Raman, MD' } }],
            'period' => { 'start' => '2026-05-22T10:00:00Z', 'end' => '2026-05-22T10:20:00Z' },
            'reasonCode' => [{ 'coding' => [{ 'system' => 'http://snomed.info/sct', 'code' => '44054006',
                                              'display' => 'Type 2 diabetes mellitus' }], 'text' => 'Diabetes management' }],
            'serviceProvider' => { 'reference' => "Organization/#{org_cvhs}", 'display' => 'Cedar Valley Health System' } }
        ],

        'Condition' => [
          { 'resourceType' => 'Condition', 'id' => 'cond-reynolds-htn',
            'meta' => { 'versionId' => '2', 'lastUpdated' => '2026-05-20T14:35:00Z' },
            'clinicalStatus' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/condition-clinical',
                                                 'code' => 'active', 'display' => 'Active' }], 'text' => 'Active' },
            'verificationStatus' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/condition-ver-status',
                                                     'code' => 'confirmed', 'display' => 'Confirmed' }] },
            'category' => [{ 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/condition-category',
                                           'code' => 'problem-list-item', 'display' => 'Problem List Item' }] }],
            'code' => { 'coding' => [{ 'system' => 'http://hl7.org/fhir/sid/icd-10-cm', 'code' => 'I10', 'display' => 'Essential (primary) hypertension' }],
                        'text' => 'Essential hypertension' },
            'subject' => { 'reference' => "Patient/#{pat_reynolds}", 'display' => 'Martha Reynolds' },
            'encounter' => { 'reference' => 'Encounter/enc-reynolds-001' },
            'onsetDateTime' => '2019-02-01T00:00:00Z', 'recordedDate' => '2019-02-05T00:00:00Z' },
          { 'resourceType' => 'Condition', 'id' => 'cond-calderon-dm2',
            'meta' => { 'versionId' => '3', 'lastUpdated' => '2026-05-22T10:20:00Z' },
            'clinicalStatus' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/condition-clinical',
                                                 'code' => 'active', 'display' => 'Active' }], 'text' => 'Active' },
            'verificationStatus' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/condition-ver-status',
                                                     'code' => 'confirmed', 'display' => 'Confirmed' }] },
            'category' => [{ 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/condition-category',
                                           'code' => 'problem-list-item', 'display' => 'Problem List Item' }] }],
            'code' => { 'coding' => [{ 'system' => 'http://hl7.org/fhir/sid/icd-10-cm', 'code' => 'E11.9', 'display' => 'Type 2 diabetes mellitus without complications' }],
                        'text' => 'Type 2 diabetes mellitus' },
            'subject' => { 'reference' => "Patient/#{pat_calderon}", 'display' => 'James Calderon' },
            'encounter' => { 'reference' => 'Encounter/enc-calderon-001' },
            'onsetDateTime' => '2021-08-15T00:00:00Z', 'recordedDate' => '2021-08-20T00:00:00Z' }
        ]
      }
    end
  }
}
