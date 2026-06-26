# frozen_string_literal: true

# ============================================================================
# Mock Workday HCM Connector -- Financial Services (Workato Connector SDK)
# ============================================================================
#
# A SELF-CONTAINED mock of a Workday HCM connector, built for live demos. It
# mirrors Workday's core HCM object model and a standard action/trigger
# surface, but serves EMBEDDED demo data:
#
#   * No external HTTP calls are ever made (no get/post/patch/etc).
#   * No real Workday auth is required (authorization type 'none').
#   * Writes are SIMULATED. A Workato connector is stateless between
#     executions, so create/update/upsert/delete synthesize and RETURN a
#     realistic result record (generated Workday-style ID + timestamps)
#     rather than mutating the embedded dataset.
#
# All seed data lives inline in the `mock_data` method below. Nothing is
# loaded from external files -- the connector is fully self-contained.
#
# Demo flavor: a believable TECHNOLOGY workforce anchored on Northwind Software
# (the same company used as the anchor account in the Salesforce Technology
# mock). Recurring cross-connector personas (Eleanor Vance, Marcus Reyes, Priya
# Raman, Tobias Greer, James Whitfield) appear here as the workforce. The
# joiner / mover / leaver (JML) story is the universal Workday use case.
# ============================================================================

{
  title: 'Mock Workday HCM (Technology)',

  # --------------------------------------------------------------------------
  # CONNECTION
  # --------------------------------------------------------------------------
  # No credentials. The single optional field is display-only -- it lets a
  # demo presenter label which "tenant" they're pretending to be connected to.
  # It is never used for auth and never sent anywhere.
  connection: {
    fields: [
      {
        name: 'tenant_label',
        label: 'Tenant label',
        optional: true,
        hint: 'Display-only. A friendly name for this mock Workday tenant. No effect on behavior.',
        default: 'Demo Workday (Technology)'
      }
    ],

    authorization: {
      type: 'none'
    }
  },

  # --------------------------------------------------------------------------
  # TEST
  # --------------------------------------------------------------------------
  # Static success payload. No network call -- always "connects".
  test: lambda do |connection|
    {
      status: 'ok',
      connected: true,
      tenant: connection['tenant_label'].presence || 'Demo Workday (Technology)',
      api_version: 'v40.0 (mock)',
      message: 'Mock Workday HCM connection succeeded (no external call was made).'
    }
  end,

  # --------------------------------------------------------------------------
  # OBJECT DEFINITIONS  (static schema per object, mirroring real Workday HCM)
  # --------------------------------------------------------------------------
  object_definitions: {
    worker: {
      fields: lambda do |_connection, _config|
        call('object_schema', 'Worker')
      end
    },

    position: {
      fields: lambda do |_connection, _config|
        call('object_schema', 'Position')
      end
    },

    organization: {
      fields: lambda do |_connection, _config|
        call('object_schema', 'Organization')
      end
    },

    leave_request: {
      fields: lambda do |_connection, _config|
        call('object_schema', 'Leave_Request')
      end
    },

    # Dynamic schema: resolves to the field list of whichever object the user
    # selected in the action input. Drives I/O for every action.
    dynamic_object: {
      fields: lambda do |_connection, config_fields|
        object = config_fields['object'].presence || 'Worker'
        call('object_schema', object)
      end
    }
  },

  # --------------------------------------------------------------------------
  # PICK LISTS
  # --------------------------------------------------------------------------
  pick_lists: {
    # The object selector shared by every action.
    objects: lambda do |_connection|
      [
        %w[Worker Worker],
        %w[Position Position],
        %w[Organization Organization],
        ['Leave request', 'Leave_Request']
      ]
    end,

    operators: lambda do |_connection|
      [
        ['equals (=)', '='],
        ['not equals (!=)', '!='],
        ['greater than (>)', '>'],
        ['greater or equal (>=)', '>='],
        ['less than (<)', '<'],
        ['less or equal (<=)', '<='],
        ['contains (LIKE)', 'LIKE'],
        ['in list (IN)', 'IN']
      ]
    end
  },

  # --------------------------------------------------------------------------
  # ACTIONS  (mirror a standard Workday HCM connector's common actions)
  # --------------------------------------------------------------------------
  actions: {

    # ---- GET RECORD --------------------------------------------------------
    get_record: {
      title: 'Get record by ID',
      subtitle: 'Retrieve a single record from mock Workday HCM',
      description: lambda do |_input, _picklist|
        'Get a <span class="provider">record</span> by ID from ' \
          '<span class="provider">mock Workday HCM</span>'
      end,
      help: 'Returns the matching seed record for the selected object. ' \
            'If no record matches the ID, a Workday-style error is raised. ' \
            'Reads from embedded demo data only -- no external call is made.',

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          control_type: 'select',
          pick_list: 'objects',
          optional: false,
          hint: 'Workday object to read.'
        }
      ],

      input_fields: lambda do |_object_definitions|
        [{ name: 'id', label: 'Record ID', optional: false,
           hint: 'The Workday ID of the record, e.g. WD-EMP-000001.' }]
      end,

      execute: lambda do |_connection, input|
        object = input['object']
        idf = call('id_field', object)
        record = call('mock_data')[object]&.find { |r| r[idf] == input['id'] }
        unless record
          error("Invalid ID value. No #{object} matches '#{input['id']}' in this tenant.")
        end
        record
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_object']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['object'].presence || 'Worker'].first
      end
    },

    # ---- SEARCH RECORDS ----------------------------------------------------
    search_records: {
      title: 'Search records',
      subtitle: 'Query mock Workday HCM with filters or a search string',
      description: lambda do |_input, _picklist|
        'Search <span class="provider">records</span> in ' \
          '<span class="provider">mock Workday HCM</span>'
      end,
      help: 'Returns matching seed records and a total count. Provide structured ' \
            'filter rows (field / operator / value, all ANDed), an optional free-text ' \
            'search string (case-insensitive substring match across all fields), or both. ' \
            'Operators: = != &gt; &gt;= &lt; &lt;= LIKE IN.',

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          control_type: 'select',
          pick_list: 'objects',
          optional: false,
          hint: 'Workday object to search.'
        }
      ],

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'filters',
            label: 'Filters',
            type: 'array',
            of: 'object',
            optional: true,
            hint: 'Each row is ANDed together.',
            properties: [
              { name: 'field', optional: false, hint: 'Field name, e.g. Department' },
              { name: 'operator', control_type: 'select', pick_list: 'operators',
                optional: false },
              { name: 'value', optional: false,
                hint: 'For IN, provide a comma-separated list.' }
            ]
          },
          {
            name: 'query',
            label: 'Search string (optional)',
            optional: true,
            hint: 'Case-insensitive substring matched across every field, e.g. Technology'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        object = input['object']
        filters = Array.wrap(input['filters']).map(&:dup)

        records = call('find_records', object, filters)
        records = call('text_search', records, input['query']) if input['query'].present?

        { total: records.length, data: records }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'total', type: 'integer' },
          { name: 'data', type: 'array', of: 'object',
            properties: object_definitions['dynamic_object'] }
        ]
      end,

      sample_output: lambda do |_connection, input|
        recs = call('mock_data')[input['object'].presence || 'Worker']
        { total: recs.length, data: recs.first(2) }
      end
    },

    # ---- CREATE RECORD -----------------------------------------------------
    create_record: {
      title: 'Create record',
      subtitle: 'Simulate creating a record in mock Workday HCM',
      description: lambda do |_input, _picklist|
        'Create a <span class="provider">record</span> in ' \
          '<span class="provider">mock Workday HCM</span> (simulated)'
      end,
      help: 'SIMULATED WRITE. The connector is stateless and never mutates the embedded ' \
            'dataset. A new Workday-style ID is generated and the record is echoed back ' \
            'with its timestamp set to now. Nothing is persisted.',

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          control_type: 'select',
          pick_list: 'objects',
          optional: false
        }
      ],

      input_fields: lambda do |object_definitions|
        # All object fields except the system-managed ones.
        object_definitions['dynamic_object'].reject do |f|
          call('system_fields').include?(f['name'])
        end
      end,

      execute: lambda do |_connection, input|
        object = input['object']
        payload = input.except('object')
        record = payload.merge(call('id_field', object) => call('generate_wd_id', object))
        call('stamp_timestamp', object, record)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_object']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['object'].presence || 'Worker'].first
      end
    },

    # ---- UPDATE RECORD -----------------------------------------------------
    update_record: {
      title: 'Update record',
      subtitle: 'Simulate updating a record in mock Workday HCM',
      description: lambda do |_input, _picklist|
        'Update a <span class="provider">record</span> in ' \
          '<span class="provider">mock Workday HCM</span> (simulated)'
      end,
      help: 'SIMULATED WRITE. Locates the seed record by ID (or synthesizes one if not ' \
            'found), merges your input over it, bumps Updated_At to now (Worker), and ' \
            'returns the result. Nothing is persisted.',

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          control_type: 'select',
          pick_list: 'objects',
          optional: false
        }
      ],

      input_fields: lambda do |object_definitions|
        flds = object_definitions['dynamic_object'].reject do |f|
          %w[Updated_At Submitted_Date].include?(f['name'])
        end
        id_fields = call('all_id_fields')
        flds.map { |f| id_fields.include?(f['name']) ? f.merge('optional' => false) : f }
      end,

      execute: lambda do |_connection, input|
        object = input['object']
        payload = input.except('object')
        idf = call('id_field', object)
        existing = call('mock_data')[object]&.find { |r| r[idf] == payload[idf] } || {}
        merged = existing.merge(payload)
        merged = merged.merge('Updated_At' => call('now_iso')) if object == 'Worker'
        merged
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_object']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['object'].presence || 'Worker'].first
      end
    },

    # ---- UPSERT RECORD -----------------------------------------------------
    upsert_record: {
      title: 'Upsert record',
      subtitle: 'Simulate upserting a record by ID',
      description: lambda do |_input, _picklist|
        'Upsert a <span class="provider">record</span> in ' \
          '<span class="provider">mock Workday HCM</span> (simulated)'
      end,
      help: 'SIMULATED WRITE. If a seed record matches the provided ID it is treated as an ' \
            'update (created=false); otherwise a new ID is generated (created=true). ' \
            'Returns the created/updated flag plus the record. Nothing is persisted.',

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          control_type: 'select',
          pick_list: 'objects',
          optional: false
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['dynamic_object'].reject do |f|
          %w[Updated_At Submitted_Date].include?(f['name'])
        end
      end,

      execute: lambda do |_connection, input|
        object = input['object']
        payload = input.except('object')
        idf = call('id_field', object)
        existing = payload[idf].present? &&
                   call('mock_data')[object]&.find { |r| r[idf] == payload[idf] }

        if existing
          record = existing.merge(payload)
          record = record.merge('Updated_At' => call('now_iso')) if object == 'Worker'
          { created: false, id: record[idf], record: record }
        else
          record = payload.merge(idf => call('generate_wd_id', object))
          record = call('stamp_timestamp', object, record)
          { created: true, id: record[idf], record: record }
        end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'created', type: 'boolean' },
          { name: 'id', label: 'ID', type: 'string' },
          { name: 'record', type: 'object',
            properties: object_definitions['dynamic_object'] }
        ]
      end,

      sample_output: lambda do |_connection, input|
        object = input['object'].presence || 'Worker'
        rec = call('mock_data')[object].first
        { created: false, id: rec[call('id_field', object)], record: rec }
      end
    },

    # ---- DELETE RECORD -----------------------------------------------------
    delete_record: {
      title: 'Delete record',
      subtitle: 'Simulate deleting a record in mock Workday HCM',
      description: lambda do |_input, _picklist|
        'Delete a <span class="provider">record</span> in ' \
          '<span class="provider">mock Workday HCM</span> (simulated)'
      end,
      help: 'SIMULATED WRITE. Returns a delete result. Nothing is persisted or actually ' \
            'removed from the embedded dataset.',

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          control_type: 'select',
          pick_list: 'objects',
          optional: false
        }
      ],

      input_fields: lambda do |_object_definitions|
        [{ name: 'id', label: 'Record ID', optional: false }]
      end,

      execute: lambda do |_connection, input|
        { id: input['id'], success: true, errors: [] }
      end,

      output_fields: lambda do |_object_definitions|
        [
          { name: 'id', label: 'ID', type: 'string' },
          { name: 'success', type: 'boolean' },
          { name: 'errors', type: 'array', of: 'string' }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        { id: 'WD-EMP-000001', success: true, errors: [] }
      end
    }
  },

  # --------------------------------------------------------------------------
  # TRIGGERS  (polling, mirroring the standard connector)
  # --------------------------------------------------------------------------
  # Each trigger is bound to a specific object and timestamp field (the
  # joiner / mover / leaver pattern), reusing the same `since`-cursor closure.
  triggers: {

    # ---- NEW WORKER --------------------------------------------------------
    new_worker: {
      title: 'New worker',
      subtitle: 'Triggers when a worker is hired (Hire_Date) in mock Workday HCM',
      description: lambda do |_input, _picklist|
        'New <span class="provider">worker</span> in ' \
          '<span class="provider">mock Workday HCM</span>'
      end,
      help: 'Polls the embedded Worker dataset for records whose Hire_Date is newer than ' \
            'the last poll. On the first poll all seed workers flow through once, then dedup ' \
            'on Worker_ID prevents repeats. This is the "joiner" event.',

      poll: lambda do |_connection, _input, closure|
        closure ||= {}
        since = closure['since'].presence || '1970-01-01T00:00:00Z'

        records = call('mock_data')['Worker']
                  .select { |r| r['Hire_Date'].present? && r['Hire_Date'] > since }
                  .sort_by { |r| r['Hire_Date'] }

        {
          events: records,
          next_poll: { 'since' => call('now_iso') },
          can_poll_more: false
        }
      end,

      dedup: lambda do |record|
        record['Worker_ID']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['worker']
      end,

      sample_output: lambda do |_connection, _input|
        call('mock_data')['Worker'].first
      end
    },

    # ---- NEW OR UPDATED WORKER ---------------------------------------------
    new_or_updated_worker: {
      title: 'New or updated worker',
      subtitle: 'Triggers when a worker is created or changed (Updated_At)',
      description: lambda do |_input, _picklist|
        'New or updated <span class="provider">worker</span> in ' \
          '<span class="provider">mock Workday HCM</span>'
      end,
      help: 'Polls the embedded Worker dataset for records whose Updated_At is newer than ' \
            'the last poll. On the first poll all seed workers flow through once. Dedup on ' \
            'Worker_ID@Updated_At lets a genuinely changed worker re-fire. This powers the ' \
            '"mover" (department transfer) and "leaver" (Status = Terminated) events.',

      poll: lambda do |_connection, _input, closure|
        closure ||= {}
        since = closure['since'].presence || '1970-01-01T00:00:00Z'

        records = call('mock_data')['Worker']
                  .select { |r| r['Updated_At'].present? && r['Updated_At'] > since }
                  .sort_by { |r| r['Updated_At'] }

        {
          events: records,
          next_poll: { 'since' => call('now_iso') },
          can_poll_more: false
        }
      end,

      dedup: lambda do |record|
        "#{record['Worker_ID']}@#{record['Updated_At']}"
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['worker']
      end,

      sample_output: lambda do |_connection, _input|
        call('mock_data')['Worker'].first
      end
    },

    # ---- NEW LEAVE REQUEST -------------------------------------------------
    new_leave_request: {
      title: 'New leave request',
      subtitle: 'Triggers when a leave request is submitted (Submitted_Date)',
      description: lambda do |_input, _picklist|
        'New <span class="provider">leave request</span> in ' \
          '<span class="provider">mock Workday HCM</span>'
      end,
      help: 'Polls the embedded Leave_Request dataset for records whose Submitted_Date is ' \
            'newer than the last poll. On the first poll all seed leave requests flow ' \
            'through once, then dedup on Leave_ID prevents repeats.',

      poll: lambda do |_connection, _input, closure|
        closure ||= {}
        since = closure['since'].presence || '1970-01-01T00:00:00Z'

        records = call('mock_data')['Leave_Request']
                  .select { |r| r['Submitted_Date'].present? && r['Submitted_Date'] > since }
                  .sort_by { |r| r['Submitted_Date'] }

        {
          events: records,
          next_poll: { 'since' => call('now_iso') },
          can_poll_more: false
        }
      end,

      dedup: lambda do |record|
        record['Leave_ID']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['leave_request']
      end,

      sample_output: lambda do |_connection, _input|
        call('mock_data')['Leave_Request'].first
      end
    }
  },

  # --------------------------------------------------------------------------
  # METHODS  (reusable logic -- data access, filtering, ID generation, schema)
  # --------------------------------------------------------------------------
  methods: {

    # Field list for a given object, reused by object_definitions and triggers.
    # Keeps the schema in one place so action I/O matches read output.
    object_schema: lambda do |object|
      schemas = {
        'Worker' => [
          { name: 'Worker_ID', label: 'Worker ID', type: 'string' },
          { name: 'Employee_Number', label: 'Employee Number', type: 'string' },
          { name: 'Legal_Name', label: 'Legal Name', type: 'object', properties: [
            { name: 'First_Name', label: 'First Name', type: 'string' },
            { name: 'Last_Name', label: 'Last Name', type: 'string' }
          ] },
          { name: 'Preferred_Name', label: 'Preferred Name', type: 'object', properties: [
            { name: 'First_Name', label: 'First Name', type: 'string' },
            { name: 'Last_Name', label: 'Last Name', type: 'string' }
          ] },
          { name: 'Email', type: 'string' },
          { name: 'Position_Title', label: 'Position Title', type: 'string' },
          { name: 'Department', type: 'string' },
          { name: 'Cost_Center', label: 'Cost Center', type: 'string' },
          { name: 'Manager_ID', label: 'Manager ID', type: 'string' },
          { name: 'Hire_Date', label: 'Hire Date', type: 'date' },
          { name: 'Status', type: 'string' },
          { name: 'Worker_Type', label: 'Worker Type', type: 'string' },
          { name: 'Location', type: 'string' },
          { name: 'Work_Phone', label: 'Work Phone', type: 'string' },
          { name: 'Start_Date', label: 'Start Date', type: 'date' },
          { name: 'Updated_At', label: 'Updated At', type: 'date_time' }
        ],
        'Position' => [
          { name: 'Position_ID', label: 'Position ID', type: 'string' },
          { name: 'Title', type: 'string' },
          { name: 'Department', type: 'string' },
          { name: 'Grade', type: 'string' },
          { name: 'Is_Open', label: 'Is Open', type: 'boolean' },
          { name: 'Headcount_Budget', label: 'Headcount Budget', type: 'integer' },
          { name: 'Incumbent_ID', label: 'Incumbent ID', type: 'string' }
        ],
        'Organization' => [
          { name: 'Org_ID', label: 'Org ID', type: 'string' },
          { name: 'Name', type: 'string' },
          { name: 'Org_Type', label: 'Org Type', type: 'string' },
          { name: 'Manager_ID', label: 'Manager ID', type: 'string' },
          { name: 'Parent_Org_ID', label: 'Parent Org ID', type: 'string' },
          { name: 'Member_Count', label: 'Member Count', type: 'integer' }
        ],
        'Leave_Request' => [
          { name: 'Leave_ID', label: 'Leave ID', type: 'string' },
          { name: 'Worker_ID', label: 'Worker ID', type: 'string' },
          { name: 'Leave_Type', label: 'Leave Type', type: 'string' },
          { name: 'Start_Date', label: 'Start Date', type: 'date' },
          { name: 'End_Date', label: 'End Date', type: 'date' },
          { name: 'Status', type: 'string' },
          { name: 'Total_Days', label: 'Total Days', type: 'integer' },
          { name: 'Submitted_Date', label: 'Submitted Date', type: 'date_time' },
          { name: 'Approved_By', label: 'Approved By', type: 'string' }
        ]
      }
      schemas[object] || schemas['Worker']
    end,

    # The primary-key field name for each object.
    id_field: lambda do |object|
      {
        'Worker' => 'Worker_ID',
        'Position' => 'Position_ID',
        'Organization' => 'Org_ID',
        'Leave_Request' => 'Leave_ID'
      }[object] || 'Worker_ID'
    end,

    # All primary-key field names (used to mark the ID input required on update).
    all_id_fields: lambda do
      %w[Worker_ID Position_ID Org_ID Leave_ID]
    end,

    # System-managed fields excluded from create input (auto-generated/stamped).
    system_fields: lambda do
      %w[Worker_ID Position_ID Org_ID Leave_ID Updated_At Submitted_Date]
    end,

    # Stamp the object's natural timestamp field with "now" on create.
    stamp_timestamp: lambda do |object, record|
      now = call('now_iso')
      case object
      when 'Worker' then record.merge('Updated_At' => now)
      when 'Leave_Request' then record.merge('Submitted_Date' => now)
      else record
      end
    end,

    # now, ISO-8601 / UTC.
    now_iso: lambda do
      Time.now.utc.iso8601
    end,

    # ------------------------------------------------------------------------
    # generate_wd_id -- builds a Workday-style ID for the given object.
    # Layout: object prefix (WD-EMP-/WD-POS-/WD-ORG-/WD-LVE-) + 6-digit body.
    # The body is generated in the 900000-999999 range so synthesized IDs
    # never collide with the seed records (000001-000008).
    # ------------------------------------------------------------------------
    generate_wd_id: lambda do |object|
      prefixes = {
        'Worker' => 'WD-EMP-', 'Position' => 'WD-POS-',
        'Organization' => 'WD-ORG-', 'Leave_Request' => 'WD-LVE-'
      }
      prefix = prefixes[object] || 'WD-EMP-'
      format('%s%06d', prefix, 900_000 + rand(100_000))
    end,

    # find_records -- the read path: fetch an object's seed records and filter.
    find_records: lambda do |object, filters|
      records = call('mock_data')[object]
      error("Unknown object: #{object}") if records.nil?
      call('apply_filters', records, filters)
    end,

    # ------------------------------------------------------------------------
    # apply_filters -- in-memory predicate matching. Each filter row is
    # { 'field' =>, 'operator' =>, 'value' => } and all rows are ANDed.
    # Operators: = != > >= < <= LIKE IN. Numeric comparison when both sides
    # look numeric; otherwise string comparison.
    # ------------------------------------------------------------------------
    apply_filters: lambda do |records, filters|
      filters = Array.wrap(filters)
      return records if filters.empty?

      records.select do |record|
        filters.all? do |f|
          field = f['field']
          op = (f['operator'] || '=').to_s.upcase
          target = f['value']
          actual = record[field]

          case op
          when '=', '=='
            call('coerce_equal', actual, target)
          when '!=', '<>'
            !call('coerce_equal', actual, target)
          when '>', '>=', '<', '<='
            cmp = call('compare_values', actual, target)
            next false if cmp.nil?

            case op
            when '>'  then cmp.positive?
            when '>=' then cmp >= 0
            when '<'  then cmp.negative?
            when '<=' then cmp <= 0
            end
          when 'LIKE'
            # SQL-style % wildcard, case-insensitive.
            pattern = Regexp.escape(target.to_s).gsub('%', '.*')
            actual.to_s.match?(/\A#{pattern}\z/i)
          when 'IN'
            list = target.is_a?(Array) ? target : target.to_s.split(',').map(&:strip)
            list.any? { |v| call('coerce_equal', actual, v) }
          else
            error("Unsupported operator: #{op}")
          end
        end
      end
    end,

    # Loose equality: numeric when both look numeric, else case-sensitive string.
    coerce_equal: lambda do |actual, target|
      if call('numeric_like?', actual) && call('numeric_like?', target)
        actual.to_f == target.to_f
      elsif [true, false].include?(actual)
        actual.to_s == target.to_s.downcase
      else
        actual.to_s == target.to_s
      end
    end,

    # Returns -1/0/1 like the spaceship operator, or nil if not comparable.
    compare_values: lambda do |actual, target|
      if call('numeric_like?', actual) && call('numeric_like?', target)
        actual.to_f <=> target.to_f
      else
        actual.to_s <=> target.to_s
      end
    end,

    numeric_like?: lambda do |v|
      return true if v.is_a?(Numeric)
      return false if v.nil?

      v.to_s.match?(/\A-?\d+(\.\d+)?\z/)
    end,

    # ------------------------------------------------------------------------
    # text_search -- case-insensitive substring match of `query` against every
    # (recursively flattened) string value in each record. Workday has no SOQL;
    # this mimics a simple WQL-style free-text search over the result set.
    # ------------------------------------------------------------------------
    text_search: lambda do |records, query|
      q = query.to_s.downcase
      records.select do |record|
        call('flatten_strings', record).any? { |v| v.downcase.include?(q) }
      end
    end,

    # Recursively collect all scalar values (as strings) from nested hashes/arrays.
    flatten_strings: lambda do |value|
      case value
      when Hash then value.values.flat_map { |v| call('flatten_strings', v) }
      when Array then value.flat_map { |v| call('flatten_strings', v) }
      when nil then []
      else [value.to_s]
      end
    end,

    # ========================================================================
    # mock_data -- the ENTIRE embedded dataset. Internally consistent:
    #   * 5 Organizations (Company / Departments / Cost Centers).
    #   * 8 Workers forming a valid Manager_ID hierarchy; every Cost_Center,
    #     Manager_ID, and Worker_ID reference resolves to a real seed record.
    #   * 6 Positions (one open req for the joiner demo).
    #   * 4 Leave_Requests (one Submitted, for the new_leave_request demo).
    # A believable TECHNOLOGY workforce anchored on Northwind Software. All IDs
    # are stable so demos and dedup behave deterministically. Cross-connector
    # personas: Eleanor Vance, Marcus Reyes, Priya Raman, Tobias Greer, and
    # James Whitfield also appear in the Salesforce Technology mock.
    # ========================================================================
    mock_data: lambda do
      {
        'Organization' => [
          { 'Org_ID' => 'WD-ORG-000001', 'Name' => 'Northwind Software',
            'Org_Type' => 'Company', 'Manager_ID' => 'WD-EMP-000001',
            'Parent_Org_ID' => nil, 'Member_Count' => 8 },
          { 'Org_ID' => 'WD-ORG-000002', 'Name' => 'Engineering',
            'Org_Type' => 'Department', 'Manager_ID' => 'WD-EMP-000003',
            'Parent_Org_ID' => 'WD-ORG-000001', 'Member_Count' => 4 },
          { 'Org_ID' => 'WD-ORG-000003', 'Name' => 'Human Resources',
            'Org_Type' => 'Department', 'Manager_ID' => 'WD-EMP-000002',
            'Parent_Org_ID' => 'WD-ORG-000001', 'Member_Count' => 2 },
          { 'Org_ID' => 'WD-ORG-000004', 'Name' => 'CC-10001 Engineering',
            'Org_Type' => 'Cost_Center', 'Manager_ID' => 'WD-EMP-000003',
            'Parent_Org_ID' => 'WD-ORG-000002', 'Member_Count' => 5 },
          { 'Org_ID' => 'WD-ORG-000005', 'Name' => 'CC-10002 Corporate',
            'Org_Type' => 'Cost_Center', 'Manager_ID' => 'WD-EMP-000002',
            'Parent_Org_ID' => 'WD-ORG-000001', 'Member_Count' => 3 }
        ],

        'Worker' => [
          # 1. C-suite -- top of the hierarchy (no manager above).
          { 'Worker_ID' => 'WD-EMP-000001', 'Employee_Number' => 'E10001',
            'Legal_Name' => { 'First_Name' => 'Eleanor', 'Last_Name' => 'Vance' },
            'Preferred_Name' => { 'First_Name' => 'Eleanor', 'Last_Name' => 'Vance' },
            'Email' => 'eleanor.vance@northwindsoftware.example.com',
            'Position_Title' => 'Chief Operating Officer', 'Department' => 'Executive',
            'Cost_Center' => 'CC-10002', 'Manager_ID' => nil,
            'Hire_Date' => '2009-03-02', 'Status' => 'Active', 'Worker_Type' => 'Employee',
            'Location' => 'Seattle, WA', 'Work_Phone' => '+1-206-555-0101',
            'Start_Date' => '2018-01-01', 'Updated_At' => '2026-01-12T15:30:00Z' },

          # 2. Director of HR.
          { 'Worker_ID' => 'WD-EMP-000002', 'Employee_Number' => 'E10002',
            'Legal_Name' => { 'First_Name' => 'Marcus', 'Last_Name' => 'Reyes' },
            'Preferred_Name' => { 'First_Name' => 'Marcus', 'Last_Name' => 'Reyes' },
            'Email' => 'marcus.reyes@northwindsoftware.example.com',
            'Position_Title' => 'Director of Human Resources', 'Department' => 'Human Resources',
            'Cost_Center' => 'CC-10002', 'Manager_ID' => 'WD-EMP-000001',
            'Hire_Date' => '2014-06-16', 'Status' => 'Active', 'Worker_Type' => 'Employee',
            'Location' => 'Seattle, WA', 'Work_Phone' => '+1-206-555-0102',
            'Start_Date' => '2020-03-01', 'Updated_At' => '2025-11-04T10:15:00Z' },

          # 3. Director of Engineering.
          { 'Worker_ID' => 'WD-EMP-000003', 'Employee_Number' => 'E10003',
            'Legal_Name' => { 'First_Name' => 'Priya', 'Last_Name' => 'Raman' },
            'Preferred_Name' => { 'First_Name' => 'Priya', 'Last_Name' => 'Raman' },
            'Email' => 'priya.raman@northwindsoftware.example.com',
            'Position_Title' => 'Director of Engineering', 'Department' => 'Engineering',
            'Cost_Center' => 'CC-10001', 'Manager_ID' => 'WD-EMP-000001',
            'Hire_Date' => '2013-09-09', 'Status' => 'Active', 'Worker_Type' => 'Employee',
            'Location' => 'Seattle, WA', 'Work_Phone' => '+1-206-555-0103',
            'Start_Date' => '2019-07-01', 'Updated_At' => '2026-02-20T09:00:00Z' },

          # 4. Director of Information Technology.
          { 'Worker_ID' => 'WD-EMP-000004', 'Employee_Number' => 'E10004',
            'Legal_Name' => { 'First_Name' => 'Tobias', 'Last_Name' => 'Greer' },
            'Preferred_Name' => { 'First_Name' => 'Tobias', 'Last_Name' => 'Greer' },
            'Email' => 'tobias.greer@northwindsoftware.example.com',
            'Position_Title' => 'Director of Information Technology', 'Department' => 'Technology',
            'Cost_Center' => 'CC-10001', 'Manager_ID' => 'WD-EMP-000001',
            'Hire_Date' => '2016-02-01', 'Status' => 'Active', 'Worker_Type' => 'Employee',
            'Location' => 'Bellevue, WA', 'Work_Phone' => '+1-425-555-0104',
            'Start_Date' => '2021-04-01', 'Updated_At' => '2025-09-18T13:45:00Z' },

          # 5. Recently hired individual contributor (within 45 days of 2025-01-01).
          { 'Worker_ID' => 'WD-EMP-000005', 'Employee_Number' => 'E10005',
            'Legal_Name' => { 'First_Name' => 'Hannah', 'Last_Name' => 'Brooks' },
            'Preferred_Name' => { 'First_Name' => 'Hannah', 'Last_Name' => 'Brooks' },
            'Email' => 'hannah.brooks@northwindsoftware.example.com',
            'Position_Title' => 'Software Engineer', 'Department' => 'Engineering',
            'Cost_Center' => 'CC-10001', 'Manager_ID' => 'WD-EMP-000003',
            'Hire_Date' => '2025-01-06', 'Status' => 'Active', 'Worker_Type' => 'Employee',
            'Location' => 'Seattle, WA', 'Work_Phone' => '+1-206-555-0105',
            'Start_Date' => '2025-01-06', 'Updated_At' => '2025-01-06T09:00:00Z' },

          # 6. Mid-tenure individual contributor / mover.
          { 'Worker_ID' => 'WD-EMP-000006', 'Employee_Number' => 'E10006',
            'Legal_Name' => { 'First_Name' => 'Daniel', 'Last_Name' => 'Osei' },
            'Preferred_Name' => { 'First_Name' => 'Daniel', 'Last_Name' => 'Osei' },
            'Email' => 'daniel.osei@northwindsoftware.example.com',
            'Position_Title' => 'Site Reliability Engineer', 'Department' => 'Technology',
            'Cost_Center' => 'CC-10001', 'Manager_ID' => 'WD-EMP-000004',
            'Hire_Date' => '2019-04-22', 'Status' => 'Active', 'Worker_Type' => 'Employee',
            'Location' => 'Portland, OR', 'Work_Phone' => '+1-503-555-0106',
            'Start_Date' => '2019-04-22', 'Updated_At' => '2025-12-01T08:30:00Z' },

          # 7. Worker currently On_Leave (references WD-LVE-000001).
          { 'Worker_ID' => 'WD-EMP-000007', 'Employee_Number' => 'E10007',
            'Legal_Name' => { 'First_Name' => 'Maria', 'Last_Name' => 'Santos' },
            'Preferred_Name' => { 'First_Name' => 'Maria', 'Last_Name' => 'Santos' },
            'Email' => 'maria.santos@northwindsoftware.example.com',
            'Position_Title' => 'HR Generalist', 'Department' => 'Human Resources',
            'Cost_Center' => 'CC-10002', 'Manager_ID' => 'WD-EMP-000002',
            'Hire_Date' => '2018-08-13', 'Status' => 'On_Leave', 'Worker_Type' => 'Employee',
            'Location' => 'Seattle, WA', 'Work_Phone' => '+1-206-555-0107',
            'Start_Date' => '2018-08-13', 'Updated_At' => '2026-03-15T09:25:00Z' },

          # 8. Contractor.
          { 'Worker_ID' => 'WD-EMP-000008', 'Employee_Number' => 'C20001',
            'Legal_Name' => { 'First_Name' => 'James', 'Last_Name' => 'Whitfield' },
            'Preferred_Name' => { 'First_Name' => 'James', 'Last_Name' => 'Whitfield' },
            'Email' => 'james.whitfield@contractor.northwindsoftware.example.com',
            'Position_Title' => 'IT Support Contractor', 'Department' => 'Technology',
            'Cost_Center' => 'CC-10001', 'Manager_ID' => 'WD-EMP-000004',
            'Hire_Date' => '2024-10-01', 'Status' => 'Active', 'Worker_Type' => 'Contractor',
            'Location' => 'Remote', 'Work_Phone' => '+1-206-555-0108',
            'Start_Date' => '2024-10-01', 'Updated_At' => '2025-10-01T12:00:00Z' }
        ],

        'Position' => [
          { 'Position_ID' => 'WD-POS-000001', 'Title' => 'Chief Operating Officer',
            'Department' => 'Executive', 'Grade' => 'Grade-15', 'Is_Open' => false,
            'Headcount_Budget' => 1, 'Incumbent_ID' => 'WD-EMP-000001' },
          { 'Position_ID' => 'WD-POS-000002', 'Title' => 'Director of Human Resources',
            'Department' => 'Human Resources', 'Grade' => 'Grade-13', 'Is_Open' => false,
            'Headcount_Budget' => 1, 'Incumbent_ID' => 'WD-EMP-000002' },
          { 'Position_ID' => 'WD-POS-000003', 'Title' => 'Director of Engineering',
            'Department' => 'Engineering', 'Grade' => 'Grade-13', 'Is_Open' => false,
            'Headcount_Budget' => 1, 'Incumbent_ID' => 'WD-EMP-000003' },
          { 'Position_ID' => 'WD-POS-000004', 'Title' => 'Director of Information Technology',
            'Department' => 'Technology', 'Grade' => 'Grade-13', 'Is_Open' => false,
            'Headcount_Budget' => 1, 'Incumbent_ID' => 'WD-EMP-000004' },
          # Open req -- the target for the "joiner" demo.
          { 'Position_ID' => 'WD-POS-000005', 'Title' => 'Senior Software Engineer',
            'Department' => 'Engineering', 'Grade' => 'Grade-10', 'Is_Open' => true,
            'Headcount_Budget' => 2, 'Incumbent_ID' => nil },
          { 'Position_ID' => 'WD-POS-000006', 'Title' => 'Software Engineer',
            'Department' => 'Engineering', 'Grade' => 'Grade-08', 'Is_Open' => false,
            'Headcount_Budget' => 1, 'Incumbent_ID' => 'WD-EMP-000005' }
        ],

        'Leave_Request' => [
          # Maria Santos (WD-EMP-000007) -- ties to her On_Leave status.
          { 'Leave_ID' => 'WD-LVE-000001', 'Worker_ID' => 'WD-EMP-000007',
            'Leave_Type' => 'Parental', 'Start_Date' => '2026-05-01',
            'End_Date' => '2026-08-01', 'Status' => 'Active', 'Total_Days' => 66,
            'Submitted_Date' => '2026-03-15T09:20:00Z', 'Approved_By' => 'WD-EMP-000002' },
          { 'Leave_ID' => 'WD-LVE-000002', 'Worker_ID' => 'WD-EMP-000006',
            'Leave_Type' => 'PTO', 'Start_Date' => '2026-07-06',
            'End_Date' => '2026-07-10', 'Status' => 'Approved', 'Total_Days' => 5,
            'Submitted_Date' => '2026-06-01T14:05:00Z', 'Approved_By' => 'WD-EMP-000004' },
          # Newly Submitted -- the target for the new_leave_request demo.
          { 'Leave_ID' => 'WD-LVE-000003', 'Worker_ID' => 'WD-EMP-000005',
            'Leave_Type' => 'FMLA', 'Start_Date' => '2026-06-29',
            'End_Date' => '2026-07-24', 'Status' => 'Submitted', 'Total_Days' => 20,
            'Submitted_Date' => '2026-06-25T11:30:00Z', 'Approved_By' => nil },
          { 'Leave_ID' => 'WD-LVE-000004', 'Worker_ID' => 'WD-EMP-000008',
            'Leave_Type' => 'Medical', 'Start_Date' => '2026-04-02',
            'End_Date' => '2026-04-09', 'Status' => 'Returned', 'Total_Days' => 6,
            'Submitted_Date' => '2026-03-20T08:00:00Z', 'Approved_By' => 'WD-EMP-000004' }
        ]
      }
    end
  }
}
