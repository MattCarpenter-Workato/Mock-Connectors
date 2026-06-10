# frozen_string_literal: true

# ============================================================================
# Mock Salesforce Connector (Workato Connector SDK)
# ============================================================================
#
# A SELF-CONTAINED mock of Workato's standard Salesforce connector, built for
# live demos. It mirrors the standard connector's object model and
# action/trigger surface, but serves EMBEDDED demo data:
#
#   * No external HTTP calls are ever made (no get/post/patch/etc).
#   * No real Salesforce auth is required (authorization type 'none').
#   * Writes are SIMULATED. A Workato connector is stateless between
#     executions, so create/update/upsert/delete synthesize and RETURN a
#     realistic result record (generated 18-char Salesforce-style Id +
#     timestamps) rather than mutating the embedded dataset.
#
# All seed data lives inline in the `mock_data` method below. Nothing is
# loaded from external files -- the connector is fully self-contained.
#
# Demo flavor: a believable HEALTHCARE / LIFE SCIENCES CRM (hospitals &
# providers, payers/health plans, pharma/biotech, medical devices, home care).
# ============================================================================

{
  title: 'Mock Salesforce (Healthcare)',

  # --------------------------------------------------------------------------
  # CONNECTION
  # --------------------------------------------------------------------------
  # No credentials. The single optional field is display-only -- it lets a
  # demo presenter label which "instance" they're pretending to be connected
  # to. It is never used for auth and never sent anywhere.
  connection: {
    fields: [
      {
        name: 'instance_label',
        label: 'Instance label',
        optional: true,
        hint: 'Display-only. A friendly name for this mock org. No effect on behavior.',
        default: 'Demo Salesforce (Healthcare)'
      }
    ],

    authorization: {
      type: 'none'
    },

    # No base_uri / apply block -- this connector makes no HTTP requests.
    base_uri: lambda do |_connection|
      # Returned for completeness; never used because no requests are issued.
      'https://mock.local'
    end
  },

  # --------------------------------------------------------------------------
  # TEST
  # --------------------------------------------------------------------------
  # Static success payload. No network call -- always "connects".
  test: lambda do |connection|
    {
      status: 'ok',
      connected: true,
      instance: connection['instance_label'].presence || 'Demo Salesforce (Financial Services)',
      api_version: '60.0 (mock)',
      message: 'Mock Salesforce connection succeeded (no external call was made).'
    }
  end,

  # --------------------------------------------------------------------------
  # OBJECT DEFINITIONS  (static schema per object, mirroring real Salesforce)
  # --------------------------------------------------------------------------
  object_definitions: {
    account: {
      fields: lambda do |_connection, _config|
        [
          { name: 'Id', label: 'Account ID', type: 'string' },
          { name: 'Name', label: 'Account Name', type: 'string' },
          { name: 'Industry', type: 'string' },
          { name: 'AnnualRevenue', label: 'Annual Revenue', type: 'number' },
          { name: 'Type', type: 'string' },
          { name: 'OwnerId', label: 'Owner ID', type: 'string' },
          { name: 'Website', type: 'string' },
          { name: 'CreatedDate', label: 'Created Date', type: 'date_time' },
          { name: 'LastModifiedDate', label: 'Last Modified Date', type: 'date_time' }
        ]
      end
    },

    contact: {
      fields: lambda do |_connection, _config|
        [
          { name: 'Id', label: 'Contact ID', type: 'string' },
          { name: 'FirstName', label: 'First Name', type: 'string' },
          { name: 'LastName', label: 'Last Name', type: 'string' },
          { name: 'Email', type: 'string' },
          { name: 'Title', type: 'string' },
          { name: 'AccountId', label: 'Account ID', type: 'string' },
          { name: 'OwnerId', label: 'Owner ID', type: 'string' },
          { name: 'Phone', type: 'string' },
          { name: 'CreatedDate', label: 'Created Date', type: 'date_time' },
          { name: 'LastModifiedDate', label: 'Last Modified Date', type: 'date_time' }
        ]
      end
    },

    lead: {
      fields: lambda do |_connection, _config|
        [
          { name: 'Id', label: 'Lead ID', type: 'string' },
          { name: 'FirstName', label: 'First Name', type: 'string' },
          { name: 'LastName', label: 'Last Name', type: 'string' },
          { name: 'Company', type: 'string' },
          { name: 'Email', type: 'string' },
          { name: 'Status', type: 'string' },
          { name: 'LeadSource', label: 'Lead Source', type: 'string' },
          { name: 'IsConverted', label: 'Is Converted', type: 'boolean' },
          { name: 'OwnerId', label: 'Owner ID', type: 'string' },
          { name: 'CreatedDate', label: 'Created Date', type: 'date_time' },
          { name: 'LastModifiedDate', label: 'Last Modified Date', type: 'date_time' }
        ]
      end
    },

    opportunity: {
      fields: lambda do |_connection, _config|
        [
          { name: 'Id', label: 'Opportunity ID', type: 'string' },
          { name: 'Name', type: 'string' },
          { name: 'AccountId', label: 'Account ID', type: 'string' },
          { name: 'StageName', label: 'Stage', type: 'string' },
          { name: 'Amount', type: 'number' },
          { name: 'CloseDate', label: 'Close Date', type: 'date' },
          { name: 'Probability', type: 'number' },
          { name: 'IsClosed', label: 'Is Closed', type: 'boolean' },
          { name: 'IsWon', label: 'Is Won', type: 'boolean' },
          { name: 'OwnerId', label: 'Owner ID', type: 'string' },
          { name: 'CreatedDate', label: 'Created Date', type: 'date_time' },
          { name: 'LastModifiedDate', label: 'Last Modified Date', type: 'date_time' }
        ]
      end
    },

    case: {
      fields: lambda do |_connection, _config|
        [
          { name: 'Id', label: 'Case ID', type: 'string' },
          { name: 'CaseNumber', label: 'Case Number', type: 'string' },
          { name: 'Subject', type: 'string' },
          { name: 'Status', type: 'string' },
          { name: 'Priority', type: 'string' },
          { name: 'AccountId', label: 'Account ID', type: 'string' },
          { name: 'ContactId', label: 'Contact ID', type: 'string' },
          { name: 'OwnerId', label: 'Owner ID', type: 'string' },
          { name: 'CreatedDate', label: 'Created Date', type: 'date_time' },
          { name: 'LastModifiedDate', label: 'Last Modified Date', type: 'date_time' }
        ]
      end
    },

    user: {
      fields: lambda do |_connection, _config|
        [
          { name: 'Id', label: 'User ID', type: 'string' },
          { name: 'Name', type: 'string' },
          { name: 'Email', type: 'string' },
          { name: 'IsActive', label: 'Is Active', type: 'boolean' },
          { name: 'Username', type: 'string' }
        ]
      end
    },

    # Dynamic schema: resolves to the field list of whichever object the user
    # selected in the action/trigger input. Drives I/O for every action.
    dynamic_object: {
      fields: lambda do |_connection, config_fields|
        object = config_fields['object'].presence || 'Account'
        call('object_schema', object)
      end
    }
  },

  # --------------------------------------------------------------------------
  # PICK LISTS
  # --------------------------------------------------------------------------
  pick_lists: {
    # The object selector shared by every action and trigger.
    objects: lambda do |_connection|
      [
        %w[Account Account],
        %w[Contact Contact],
        %w[Lead Lead],
        %w[Opportunity Opportunity],
        %w[Case Case],
        %w[User User]
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
    end,

    stage_names: lambda do |_connection|
      [
        'Prospecting', 'Qualification', 'Needs Analysis', 'Proposal/Price Quote',
        'Negotiation/Review', 'Closed Won', 'Closed Lost'
      ].map { |s| [s, s] }
    end,

    lead_statuses: lambda do |_connection|
      ['Open - Not Contacted', 'Working - Contacted', 'Closed - Converted',
       'Closed - Not Converted'].map { |s| [s, s] }
    end,

    case_statuses: lambda do |_connection|
      %w[New Working Escalated Closed].map { |s| [s, s] }
    end,

    case_priorities: lambda do |_connection|
      %w[Low Medium High].map { |s| [s, s] }
    end
  },

  # --------------------------------------------------------------------------
  # ACTIONS  (mirror the standard Salesforce connector's common actions)
  # --------------------------------------------------------------------------
  actions: {

    # ---- GET RECORD --------------------------------------------------------
    get_record: {
      title: 'Get record by ID',
      subtitle: 'Retrieve a single record from mock Salesforce',
      description: lambda do |_input, _picklist|
        'Get a <span class="provider">record</span> by ID from ' \
          '<span class="provider">mock Salesforce</span>'
      end,
      help: 'Returns the matching seed record for the selected object. ' \
            'If no record matches the Id, a Salesforce-style NOT_FOUND error is raised. ' \
            'Reads from embedded demo data only -- no external call is made.',

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          control_type: 'select',
          pick_list: 'objects',
          optional: false,
          hint: 'Salesforce object to read.'
        }
      ],

      input_fields: lambda do |_object_definitions|
        [{ name: 'Id', label: 'Record ID', optional: false,
           hint: 'The 18-char (or 15-char) Salesforce Id of the record.' }]
      end,

      execute: lambda do |_connection, input|
        object = input['object']
        record = call('mock_data')[object]&.find { |r| r['Id'] == input['Id'] }
        unless record
          error("NOT_FOUND: Provided external ID field does not exist or is not " \
                "accessible: #{input['Id']} (object #{object})")
        end
        record
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_object']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['object'].presence || 'Account'].first
      end
    },

    # ---- SEARCH RECORDS ----------------------------------------------------
    search_records: {
      title: 'Search records',
      subtitle: 'Query mock Salesforce with filters or SOQL-lite',
      description: lambda do |_input, _picklist|
        'Search <span class="provider">records</span> in ' \
          '<span class="provider">mock Salesforce</span>'
      end,
      help: 'Returns matching seed records and a totalSize count. Provide structured ' \
            'filter rows (field / operator / value), a raw SOQL-lite string, or both. ' \
            'SOQL-lite supports: SELECT &lt;fields|*&gt; FROM &lt;Object&gt; ' \
            'WHERE &lt;field&gt; &lt;op&gt; &lt;value&gt; [AND ...]. ' \
            'Operators: = != &gt; &gt;= &lt; &lt;= LIKE IN.',

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          control_type: 'select',
          pick_list: 'objects',
          optional: false,
          hint: 'Salesforce object to search. (Ignored if a SOQL string specifies FROM.)'
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
              { name: 'field', optional: false, hint: 'Field API name, e.g. Industry' },
              { name: 'operator', control_type: 'select', pick_list: 'operators',
                optional: false },
              { name: 'value', optional: false,
                hint: 'For IN, provide a comma-separated list.' }
            ]
          },
          {
            name: 'soql',
            label: 'SOQL query (optional)',
            optional: true,
            hint: "Raw SOQL-lite, e.g. SELECT Id, Name FROM Account WHERE Industry = 'Banking'"
          }
        ]
      end,

      execute: lambda do |_connection, input|
        object = input['object']
        filters = Array.wrap(input['filters']).map(&:dup)

        # If a raw SOQL string was provided, parse it and merge.
        if input['soql'].present?
          parsed = call('soql_lite', input['soql'])
          object = parsed['object'] if parsed['object'].present?
          filters += parsed['filters']
        end

        records = call('find_records', object, filters)

        { totalSize: records.length, done: true, records: records }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'totalSize', type: 'integer' },
          { name: 'done', type: 'boolean' },
          { name: 'records', type: 'array', of: 'object',
            properties: object_definitions['dynamic_object'] }
        ]
      end,

      sample_output: lambda do |_connection, input|
        recs = call('mock_data')[input['object'].presence || 'Account']
        { totalSize: recs.length, done: true, records: recs.first(2) }
      end
    },

    # ---- CREATE RECORD -----------------------------------------------------
    create_record: {
      title: 'Create record',
      subtitle: 'Simulate creating a record in mock Salesforce',
      description: lambda do |_input, _picklist|
        'Create a <span class="provider">record</span> in ' \
          '<span class="provider">mock Salesforce</span> (simulated)'
      end,
      help: 'SIMULATED WRITE. The connector is stateless and never mutates the embedded ' \
            'dataset. A new Salesforce-style 18-char Id is generated and the record is ' \
            'echoed back with CreatedDate and LastModifiedDate set to now. Nothing is persisted.',

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
          %w[Id CreatedDate LastModifiedDate].include?(f['name'])
        end
      end,

      execute: lambda do |_connection, input|
        object = input['object']
        payload = input.except('object')
        now = call('now_iso')
        payload.merge(
          'Id' => call('generate_sf_id', object),
          'CreatedDate' => now,
          'LastModifiedDate' => now
        )
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_object']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['object'].presence || 'Account'].first
      end
    },

    # ---- UPDATE RECORD -----------------------------------------------------
    update_record: {
      title: 'Update record',
      subtitle: 'Simulate updating a record in mock Salesforce',
      description: lambda do |_input, _picklist|
        'Update a <span class="provider">record</span> in ' \
          '<span class="provider">mock Salesforce</span> (simulated)'
      end,
      help: 'SIMULATED WRITE. Locates the seed record by Id (or synthesizes one if not ' \
            'found), merges your input over it, bumps LastModifiedDate to now, and returns ' \
            'the result. Nothing is persisted.',

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
          %w[CreatedDate LastModifiedDate].include?(f['name'])
        end
        flds.map { |f| f['name'] == 'Id' ? f.merge('optional' => false) : f }
      end,

      execute: lambda do |_connection, input|
        object = input['object']
        payload = input.except('object')
        existing = call('mock_data')[object]&.find { |r| r['Id'] == payload['Id'] } || {}
        existing.merge(payload).merge('LastModifiedDate' => call('now_iso'))
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_object']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['object'].presence || 'Account'].first
      end
    },

    # ---- UPSERT RECORD -----------------------------------------------------
    upsert_record: {
      title: 'Upsert record',
      subtitle: 'Simulate upserting a record by ID / external ID',
      description: lambda do |_input, _picklist|
        'Upsert a <span class="provider">record</span> in ' \
          '<span class="provider">mock Salesforce</span> (simulated)'
      end,
      help: 'SIMULATED WRITE. If a seed record matches the provided Id it is treated as an ' \
            'update (created=false); otherwise a new Id is generated (created=true). ' \
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
          %w[CreatedDate LastModifiedDate].include?(f['name'])
        end
      end,

      execute: lambda do |_connection, input|
        object = input['object']
        payload = input.except('object')
        now = call('now_iso')
        existing = payload['Id'].present? &&
                   call('mock_data')[object]&.find { |r| r['Id'] == payload['Id'] }

        if existing
          record = existing.merge(payload).merge('LastModifiedDate' => now)
          { created: false, id: record['Id'], record: record }
        else
          record = payload.merge(
            'Id' => call('generate_sf_id', object),
            'CreatedDate' => now,
            'LastModifiedDate' => now
          )
          { created: true, id: record['Id'], record: record }
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
        rec = call('mock_data')[input['object'].presence || 'Account'].first
        { created: false, id: rec['Id'], record: rec }
      end
    },

    # ---- DELETE RECORD -----------------------------------------------------
    delete_record: {
      title: 'Delete record',
      subtitle: 'Simulate deleting a record in mock Salesforce',
      description: lambda do |_input, _picklist|
        'Delete a <span class="provider">record</span> in ' \
          '<span class="provider">mock Salesforce</span> (simulated)'
      end,
      help: 'SIMULATED WRITE. Returns a Salesforce-style delete result. Nothing is ' \
            'persisted or actually removed from the embedded dataset.',

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
        [{ name: 'Id', label: 'Record ID', optional: false }]
      end,

      execute: lambda do |_connection, input|
        { id: input['Id'], success: true, errors: [] }
      end,

      output_fields: lambda do |_object_definitions|
        [
          { name: 'id', label: 'ID', type: 'string' },
          { name: 'success', type: 'boolean' },
          { name: 'errors', type: 'array', of: 'string' }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        { id: '001RM000003W98YYAS', success: true, errors: [] }
      end
    }
  },

  # --------------------------------------------------------------------------
  # TRIGGERS  (polling, mirroring the standard connector)
  # --------------------------------------------------------------------------
  triggers: {

    # ---- NEW RECORD --------------------------------------------------------
    new_record: {
      title: 'New record',
      subtitle: 'Triggers when a new record is created in mock Salesforce',
      description: lambda do |_input, _picklist|
        'New <span class="provider">record</span> in ' \
          '<span class="provider">mock Salesforce</span>'
      end,
      help: 'Polls the embedded dataset for records whose CreatedDate is newer than the ' \
            'last poll. On the first poll all seed records flow through once, then dedup on ' \
            'Id prevents repeats.',

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          control_type: 'select',
          pick_list: 'objects',
          optional: false
        }
      ],

      poll: lambda do |_connection, input, closure|
        closure ||= {}
        # First poll: default "since" to a far-past date so all seed records flow once.
        since = closure['since'].presence || '1970-01-01T00:00:00Z'

        records = call('mock_data')[input['object']]
                  .select { |r| r['CreatedDate'].present? && r['CreatedDate'] > since }
                  .sort_by { |r| r['CreatedDate'] }

        {
          events: records,
          next_poll: { 'since' => call('now_iso') },
          can_poll_more: false
        }
      end,

      dedup: lambda do |record|
        record['Id']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_object']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['object'].presence || 'Account'].first
      end
    },

    # ---- NEW OR UPDATED RECORD ---------------------------------------------
    new_or_updated_record: {
      title: 'New or updated record',
      subtitle: 'Triggers when a record is created or updated in mock Salesforce',
      description: lambda do |_input, _picklist|
        'New or updated <span class="provider">record</span> in ' \
          '<span class="provider">mock Salesforce</span>'
      end,
      help: 'Polls the embedded dataset for records whose LastModifiedDate is newer than ' \
            'the last poll. On the first poll all seed records flow through once, then dedup ' \
            'on Id prevents repeats.',

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          control_type: 'select',
          pick_list: 'objects',
          optional: false
        }
      ],

      poll: lambda do |_connection, input, closure|
        closure ||= {}
        since = closure['since'].presence || '1970-01-01T00:00:00Z'

        records = call('mock_data')[input['object']]
                  .select { |r| r['LastModifiedDate'].present? && r['LastModifiedDate'] > since }
                  .sort_by { |r| r['LastModifiedDate'] }

        {
          events: records,
          next_poll: { 'since' => call('now_iso') },
          can_poll_more: false
        }
      end,

      dedup: lambda do |record|
        # Include LastModifiedDate so a genuinely re-modified record can re-fire.
        "#{record['Id']}@#{record['LastModifiedDate']}"
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dynamic_object']
      end,

      sample_output: lambda do |_connection, input|
        call('mock_data')[input['object'].presence || 'Account'].first
      end
    }
  },

  # --------------------------------------------------------------------------
  # METHODS  (reusable logic -- data access, filtering, Id generation, SOQL)
  # --------------------------------------------------------------------------
  methods: {

    # Field list for a given object, reused by object_definitions['dynamic_object'].
    # Keeps the dynamic schema in one place so action I/O matches read output.
    object_schema: lambda do |object|
      schemas = {
        'Account' => [
          { name: 'Id', label: 'Account ID', type: 'string' },
          { name: 'Name', label: 'Account Name', type: 'string' },
          { name: 'Industry', type: 'string' },
          { name: 'AnnualRevenue', label: 'Annual Revenue', type: 'number' },
          { name: 'Type', type: 'string' },
          { name: 'OwnerId', label: 'Owner ID', type: 'string' },
          { name: 'Website', type: 'string' },
          { name: 'CreatedDate', label: 'Created Date', type: 'date_time' },
          { name: 'LastModifiedDate', label: 'Last Modified Date', type: 'date_time' }
        ],
        'Contact' => [
          { name: 'Id', label: 'Contact ID', type: 'string' },
          { name: 'FirstName', label: 'First Name', type: 'string' },
          { name: 'LastName', label: 'Last Name', type: 'string' },
          { name: 'Email', type: 'string' },
          { name: 'Title', type: 'string' },
          { name: 'AccountId', label: 'Account ID', type: 'string' },
          { name: 'OwnerId', label: 'Owner ID', type: 'string' },
          { name: 'Phone', type: 'string' },
          { name: 'CreatedDate', label: 'Created Date', type: 'date_time' },
          { name: 'LastModifiedDate', label: 'Last Modified Date', type: 'date_time' }
        ],
        'Lead' => [
          { name: 'Id', label: 'Lead ID', type: 'string' },
          { name: 'FirstName', label: 'First Name', type: 'string' },
          { name: 'LastName', label: 'Last Name', type: 'string' },
          { name: 'Company', type: 'string' },
          { name: 'Email', type: 'string' },
          { name: 'Status', type: 'string' },
          { name: 'LeadSource', label: 'Lead Source', type: 'string' },
          { name: 'IsConverted', label: 'Is Converted', type: 'boolean' },
          { name: 'OwnerId', label: 'Owner ID', type: 'string' },
          { name: 'CreatedDate', label: 'Created Date', type: 'date_time' },
          { name: 'LastModifiedDate', label: 'Last Modified Date', type: 'date_time' }
        ],
        'Opportunity' => [
          { name: 'Id', label: 'Opportunity ID', type: 'string' },
          { name: 'Name', type: 'string' },
          { name: 'AccountId', label: 'Account ID', type: 'string' },
          { name: 'StageName', label: 'Stage', type: 'string' },
          { name: 'Amount', type: 'number' },
          { name: 'CloseDate', label: 'Close Date', type: 'date' },
          { name: 'Probability', type: 'number' },
          { name: 'IsClosed', label: 'Is Closed', type: 'boolean' },
          { name: 'IsWon', label: 'Is Won', type: 'boolean' },
          { name: 'OwnerId', label: 'Owner ID', type: 'string' },
          { name: 'CreatedDate', label: 'Created Date', type: 'date_time' },
          { name: 'LastModifiedDate', label: 'Last Modified Date', type: 'date_time' }
        ],
        'Case' => [
          { name: 'Id', label: 'Case ID', type: 'string' },
          { name: 'CaseNumber', label: 'Case Number', type: 'string' },
          { name: 'Subject', type: 'string' },
          { name: 'Status', type: 'string' },
          { name: 'Priority', type: 'string' },
          { name: 'AccountId', label: 'Account ID', type: 'string' },
          { name: 'ContactId', label: 'Contact ID', type: 'string' },
          { name: 'OwnerId', label: 'Owner ID', type: 'string' },
          { name: 'CreatedDate', label: 'Created Date', type: 'date_time' },
          { name: 'LastModifiedDate', label: 'Last Modified Date', type: 'date_time' }
        ],
        'User' => [
          { name: 'Id', label: 'User ID', type: 'string' },
          { name: 'Name', type: 'string' },
          { name: 'Email', type: 'string' },
          { name: 'IsActive', label: 'Is Active', type: 'boolean' },
          { name: 'Username', type: 'string' }
        ]
      }
      schemas[object] || schemas['Account']
    end,

    # now, ISO-8601 / UTC.
    now_iso: lambda do
      Time.now.utc.iso8601
    end,

    # ------------------------------------------------------------------------
    # generate_sf_id -- builds an 18-char Salesforce-style Id.
    # Layout: 3-char object key prefix + 12 base62 chars (the case-sensitive
    # body) + 3-char checksum-style suffix. Real SF Ids are 15-char
    # case-sensitive plus a 3-char case-insensitive suffix; this approximates
    # the shape closely enough to be convincing in a demo.
    # ------------------------------------------------------------------------
    generate_sf_id: lambda do |object|
      prefixes = {
        'Account' => '001', 'Contact' => '003', 'Lead' => '00Q',
        'Opportunity' => '006', 'Case' => '500', 'User' => '005'
      }
      prefix = prefixes[object] || '001'
      charset = ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a # base62
      body = (1..12).map { charset.sample }.join
      suffix = (1..3).map { ('A'..'Z').to_a.sample }.join
      "#{prefix}#{body}#{suffix}"
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
    # soql_lite -- parse a small SOQL subset into { object, fields, filters }.
    # Grammar: SELECT <fields|*> FROM <Object> [WHERE <cond> [AND <cond>...]]
    # cond: <field> <op> <value>   op in = != <> > >= < <= LIKE IN
    # Values may be single-quoted strings, numbers, or (IN ...) lists.
    # On failure raises a friendly error.
    # ------------------------------------------------------------------------
    soql_lite: lambda do |query|
      q = query.to_s.strip.gsub(/\s+/, ' ')
      m = q.match(/\ASELECT\s+(.+?)\s+FROM\s+(\w+)(?:\s+WHERE\s+(.+))?\z/i)
      error("Could not parse SOQL: expected 'SELECT <fields> FROM <Object> " \
            "[WHERE ...]'. Got: #{query}") unless m

      raw_fields = m[1].strip
      object = m[2]
      # Normalize object name to our canonical casing.
      canonical = %w[Account Contact Lead Opportunity Case User]
                  .find { |o| o.casecmp?(object) } || object

      fields = raw_fields == '*' ? ['*'] : raw_fields.split(',').map(&:strip)

      filters = []
      if m[3]
        # Split on AND (case-insensitive), respecting nothing fancy.
        m[3].split(/\s+AND\s+/i).each do |clause|
          cm = clause.strip.match(/\A(\w+)\s*(=|!=|<>|>=|<=|>|<|LIKE|IN)\s*(.+)\z/i)
          error("Could not parse SOQL WHERE clause: '#{clause}'") unless cm

          field = cm[1]
          op = cm[2].upcase
          val = cm[3].strip

          value =
            if op == 'IN'
              # ('a','b',123) -> ['a','b','123']
              inner = val.gsub(/\A\(|\)\z/, '')
              inner.split(',').map { |x| call('unquote_soql', x.strip) }
            else
              call('unquote_soql', val)
            end

          filters << { 'field' => field, 'operator' => op, 'value' => value }
        end
      end

      { 'object' => canonical, 'fields' => fields, 'filters' => filters }
    end,

    # Strip surrounding single quotes from a SOQL literal.
    unquote_soql: lambda do |token|
      t = token.to_s.strip
      t =~ /\A'(.*)'\z/ ? Regexp.last_match(1) : t
    end,

    # ========================================================================
    # mock_data -- the ENTIRE embedded dataset. Internally consistent:
    #   * 5 Users act as record Owners.
    #   * Accounts reference Owners; Contacts/Opportunities/Cases reference
    #     real AccountIds, OwnerIds, and (for Cases) ContactIds.
    # A believable mid-market HEALTHCARE / LIFE SCIENCES book of business.
    # All Ids are stable so demos and dedup behave deterministically.
    # ========================================================================
    mock_data: lambda do
      {
        'User' => [
          { 'Id' => '005RM0000001AAAAAA', 'Name' => 'Dana Whitfield',
            'Email' => 'dwhitfield@demo-hc.example.com', 'IsActive' => true,
            'Username' => 'dwhitfield@demo-hc.example.com' },
          { 'Id' => '005RM0000002BBBBBB', 'Name' => 'Marcus Lindqvist',
            'Email' => 'mlindqvist@demo-hc.example.com', 'IsActive' => true,
            'Username' => 'mlindqvist@demo-hc.example.com' },
          { 'Id' => '005RM0000003CCCCCC', 'Name' => 'Priya Raman',
            'Email' => 'praman@demo-hc.example.com', 'IsActive' => true,
            'Username' => 'praman@demo-hc.example.com' },
          { 'Id' => '005RM0000004DDDDDD', 'Name' => 'Tobias Greer',
            'Email' => 'tgreer@demo-hc.example.com', 'IsActive' => true,
            'Username' => 'tgreer@demo-hc.example.com' },
          { 'Id' => '005RM0000005EEEEEE', 'Name' => 'Sofia Castellano',
            'Email' => 'scastellano@demo-hc.example.com', 'IsActive' => false,
            'Username' => 'scastellano@demo-hc.example.com' }
        ],

        'Account' => [
          { 'Id' => '001RM0000001AAAAAA', 'Name' => 'Cedar Valley Health System',
            'Industry' => 'Hospitals & Providers', 'AnnualRevenue' => 2_400_000_000, 'Type' => 'Customer',
            'OwnerId' => '005RM0000001AAAAAA', 'Website' => 'https://cedarvalleyhealth.example.com',
            'CreatedDate' => '2025-01-14T09:12:00Z', 'LastModifiedDate' => '2026-05-02T16:40:00Z' },
          { 'Id' => '001RM0000002AAAAAA', 'Name' => 'Northstar Pediatric Group',
            'Industry' => 'Ambulatory & Clinics', 'AnnualRevenue' => 78_000_000, 'Type' => 'Customer',
            'OwnerId' => '005RM0000002BBBBBB', 'Website' => 'https://northstarpediatric.example.com',
            'CreatedDate' => '2025-02-03T11:30:00Z', 'LastModifiedDate' => '2026-04-18T08:05:00Z' },
          { 'Id' => '001RM0000003AAAAAA', 'Name' => 'Helix Genomics',
            'Industry' => 'Biotechnology', 'AnnualRevenue' => 430_000_000, 'Type' => 'Customer',
            'OwnerId' => '005RM0000003CCCCCC', 'Website' => 'https://helixgenomics.example.com',
            'CreatedDate' => '2025-03-22T14:45:00Z', 'LastModifiedDate' => '2026-05-29T13:22:00Z' },
          { 'Id' => '001RM0000004AAAAAA', 'Name' => 'Asclepius Medical Devices',
            'Industry' => 'Medical Devices', 'AnnualRevenue' => 265_000_000, 'Type' => 'Prospect',
            'OwnerId' => '005RM0000001AAAAAA', 'Website' => 'https://asclepiusdevices.example.com',
            'CreatedDate' => '2025-06-10T10:00:00Z', 'LastModifiedDate' => '2026-06-01T09:15:00Z' },
          { 'Id' => '001RM0000005AAAAAA', 'Name' => 'BlueRiver Health Plan',
            'Industry' => 'Health Insurance', 'AnnualRevenue' => 1_650_000_000, 'Type' => 'Customer',
            'OwnerId' => '005RM0000004DDDDDD', 'Website' => 'https://blueriverhealthplan.example.com',
            'CreatedDate' => '2025-08-19T08:20:00Z', 'LastModifiedDate' => '2026-03-11T17:48:00Z' },
          { 'Id' => '001RM0000006AAAAAA', 'Name' => 'Meridian Home Care',
            'Industry' => 'Home Health', 'AnnualRevenue' => 56_000_000, 'Type' => 'Prospect',
            'OwnerId' => '005RM0000003CCCCCC', 'Website' => 'https://meridianhomecare.example.com',
            'CreatedDate' => '2025-11-05T15:10:00Z', 'LastModifiedDate' => '2026-05-20T12:00:00Z' }
        ],

        'Contact' => [
          { 'Id' => '003RM0000001AAAAAA', 'FirstName' => 'Eleanor', 'LastName' => 'Voss',
            'Email' => 'eleanor.voss@cedarvalleyhealth.example.com', 'Title' => 'Chief Medical Officer',
            'AccountId' => '001RM0000001AAAAAA', 'OwnerId' => '005RM0000001AAAAAA',
            'Phone' => '+1-212-555-0142',
            'CreatedDate' => '2025-01-15T10:00:00Z', 'LastModifiedDate' => '2026-05-02T16:41:00Z' },
          { 'Id' => '003RM0000002AAAAAA', 'FirstName' => 'Raj', 'LastName' => 'Patel',
            'Email' => 'raj.patel@cedarvalleyhealth.example.com', 'Title' => 'VP, Clinical Informatics',
            'AccountId' => '001RM0000001AAAAAA', 'OwnerId' => '005RM0000001AAAAAA',
            'Phone' => '+1-212-555-0188',
            'CreatedDate' => '2025-01-20T13:25:00Z', 'LastModifiedDate' => '2026-02-14T11:10:00Z' },
          { 'Id' => '003RM0000003AAAAAA', 'FirstName' => 'Grace', 'LastName' => 'Okafor',
            'Email' => 'grace.okafor@northstarpediatric.example.com', 'Title' => 'Director of Revenue Cycle',
            'AccountId' => '001RM0000002AAAAAA', 'OwnerId' => '005RM0000002BBBBBB',
            'Phone' => '+1-617-555-0199',
            'CreatedDate' => '2025-02-05T09:40:00Z', 'LastModifiedDate' => '2026-04-18T08:06:00Z' },
          { 'Id' => '003RM0000004AAAAAA', 'FirstName' => 'Liam', 'LastName' => 'Donnelly',
            'Email' => 'liam.donnelly@helixgenomics.example.com', 'Title' => 'VP, Regulatory Affairs',
            'AccountId' => '001RM0000003AAAAAA', 'OwnerId' => '005RM0000003CCCCCC',
            'Phone' => '+1-415-555-0123',
            'CreatedDate' => '2025-03-25T16:00:00Z', 'LastModifiedDate' => '2026-05-29T13:23:00Z' },
          { 'Id' => '003RM0000005AAAAAA', 'FirstName' => 'Hannah', 'LastName' => 'Kim',
            'Email' => 'hannah.kim@asclepiusdevices.example.com', 'Title' => 'Director of Population Health',
            'AccountId' => '001RM0000004AAAAAA', 'OwnerId' => '005RM0000001AAAAAA',
            'Phone' => '+1-646-555-0177',
            'CreatedDate' => '2025-06-12T12:30:00Z', 'LastModifiedDate' => '2026-06-01T09:16:00Z' },
          { 'Id' => '003RM0000006AAAAAA', 'FirstName' => 'Marcus', 'LastName' => 'Bauer',
            'Email' => 'marcus.bauer@blueriverhealthplan.example.com', 'Title' => 'Head of Payer Relations',
            'AccountId' => '001RM0000005AAAAAA', 'OwnerId' => '005RM0000004DDDDDD',
            'Phone' => '+1-303-555-0166',
            'CreatedDate' => '2025-08-21T14:15:00Z', 'LastModifiedDate' => '2026-03-11T17:49:00Z' },
          { 'Id' => '003RM0000007AAAAAA', 'FirstName' => 'Yuki', 'LastName' => 'Tanaka',
            'Email' => 'yuki.tanaka@meridianhomecare.example.com', 'Title' => 'Chief Nursing Officer',
            'AccountId' => '001RM0000006AAAAAA', 'OwnerId' => '005RM0000003CCCCCC',
            'Phone' => '+1-312-555-0150',
            'CreatedDate' => '2025-11-06T10:05:00Z', 'LastModifiedDate' => '2026-05-20T12:01:00Z' }
        ],

        'Lead' => [
          { 'Id' => '00QRM0000001AAAAAA', 'FirstName' => 'Olivia', 'LastName' => 'Nash',
            'Company' => 'Lakeshore Surgical Center', 'Email' => 'onash@lakeshoresurgical.example.com',
            'Status' => 'Open - Not Contacted', 'LeadSource' => 'Web', 'IsConverted' => false,
            'OwnerId' => '005RM0000002BBBBBB',
            'CreatedDate' => '2026-04-02T09:00:00Z', 'LastModifiedDate' => '2026-04-02T09:00:00Z' },
          { 'Id' => '00QRM0000002AAAAAA', 'FirstName' => 'Devon', 'LastName' => 'Reyes',
            'Company' => 'Evergreen Dental Partners', 'Email' => 'dreyes@evergreendental.example.com',
            'Status' => 'Working - Contacted', 'LeadSource' => 'Trade Show', 'IsConverted' => false,
            'OwnerId' => '005RM0000003CCCCCC',
            'CreatedDate' => '2026-04-20T11:45:00Z', 'LastModifiedDate' => '2026-05-15T10:30:00Z' },
          { 'Id' => '00QRM0000003AAAAAA', 'FirstName' => 'Amara', 'LastName' => 'Singh',
            'Company' => 'Apex Diagnostics Lab', 'Email' => 'asingh@apexdiagnostics.example.com',
            'Status' => 'Working - Contacted', 'LeadSource' => 'Referral', 'IsConverted' => false,
            'OwnerId' => '005RM0000001AAAAAA',
            'CreatedDate' => '2026-05-08T13:20:00Z', 'LastModifiedDate' => '2026-05-28T15:05:00Z' },
          { 'Id' => '00QRM0000004AAAAAA', 'FirstName' => 'Felix', 'LastName' => 'Moreau',
            'Company' => 'Unity Behavioral Health', 'Email' => 'fmoreau@unitybehavioral.example.com',
            'Status' => 'Closed - Converted', 'LeadSource' => 'Partner', 'IsConverted' => true,
            'OwnerId' => '005RM0000004DDDDDD',
            'CreatedDate' => '2026-02-11T08:10:00Z', 'LastModifiedDate' => '2026-03-30T09:50:00Z' },
          { 'Id' => '00QRM0000005AAAAAA', 'FirstName' => 'Bianca', 'LastName' => 'Ferraro',
            'Company' => 'Coastal Radiology Associates', 'Email' => 'bferraro@coastalradiology.example.com',
            'Status' => 'Open - Not Contacted', 'LeadSource' => 'Web', 'IsConverted' => false,
            'OwnerId' => '005RM0000002BBBBBB',
            'CreatedDate' => '2026-06-03T07:55:00Z', 'LastModifiedDate' => '2026-06-03T07:55:00Z' }
        ],

        'Opportunity' => [
          { 'Id' => '006RM0000001AAAAAA', 'Name' => 'Cedar Valley - EHR Modernization',
            'AccountId' => '001RM0000001AAAAAA', 'StageName' => 'Negotiation/Review',
            'Amount' => 1_250_000, 'CloseDate' => '2026-07-31', 'Probability' => 75,
            'IsClosed' => false, 'IsWon' => false, 'OwnerId' => '005RM0000001AAAAAA',
            'CreatedDate' => '2026-01-18T09:30:00Z', 'LastModifiedDate' => '2026-05-02T16:42:00Z' },
          { 'Id' => '006RM0000002AAAAAA', 'Name' => 'BlueRiver - Claims Automation',
            'AccountId' => '001RM0000005AAAAAA', 'StageName' => 'Proposal/Price Quote',
            'Amount' => 480_000, 'CloseDate' => '2026-08-15', 'Probability' => 60,
            'IsClosed' => false, 'IsWon' => false, 'OwnerId' => '005RM0000004DDDDDD',
            'CreatedDate' => '2026-02-08T10:15:00Z', 'LastModifiedDate' => '2026-04-18T08:07:00Z' },
          { 'Id' => '006RM0000003AAAAAA', 'Name' => 'Northstar - Patient Engagement Portal',
            'AccountId' => '001RM0000002AAAAAA', 'StageName' => 'Closed Won',
            'Amount' => 220_000, 'CloseDate' => '2026-03-31', 'Probability' => 100,
            'IsClosed' => true, 'IsWon' => true, 'OwnerId' => '005RM0000002BBBBBB',
            'CreatedDate' => '2025-12-01T14:00:00Z', 'LastModifiedDate' => '2026-03-31T18:00:00Z' },
          { 'Id' => '006RM0000004AAAAAA', 'Name' => 'Asclepius - Telehealth Platform Rollout',
            'AccountId' => '001RM0000004AAAAAA', 'StageName' => 'Qualification',
            'Amount' => 95_000, 'CloseDate' => '2026-09-30', 'Probability' => 30,
            'IsClosed' => false, 'IsWon' => false, 'OwnerId' => '005RM0000001AAAAAA',
            'CreatedDate' => '2026-05-12T11:20:00Z', 'LastModifiedDate' => '2026-06-01T09:17:00Z' },
          { 'Id' => '006RM0000005AAAAAA', 'Name' => 'Meridian - Lab Integration (HL7/FHIR)',
            'AccountId' => '001RM0000006AAAAAA', 'StageName' => 'Closed Lost',
            'Amount' => 150_000, 'CloseDate' => '2026-02-28', 'Probability' => 0,
            'IsClosed' => true, 'IsWon' => false, 'OwnerId' => '005RM0000003CCCCCC',
            'CreatedDate' => '2025-10-15T09:00:00Z', 'LastModifiedDate' => '2026-02-28T17:30:00Z' },
          { 'Id' => '006RM0000006AAAAAA', 'Name' => 'Helix - Population Health Analytics',
            'AccountId' => '001RM0000003AAAAAA', 'StageName' => 'Needs Analysis',
            'Amount' => 610_000, 'CloseDate' => '2026-10-31', 'Probability' => 45,
            'IsClosed' => false, 'IsWon' => false, 'OwnerId' => '005RM0000003CCCCCC',
            'CreatedDate' => '2026-03-09T13:40:00Z', 'LastModifiedDate' => '2026-05-20T12:02:00Z' }
        ],

        'Case' => [
          { 'Id' => '500RM0000001AAAAAA', 'CaseNumber' => '00001001',
            'Subject' => 'HL7 interface dropping ADT messages', 'Status' => 'Working',
            'Priority' => 'High', 'AccountId' => '001RM0000001AAAAAA',
            'ContactId' => '003RM0000002AAAAAA', 'OwnerId' => '005RM0000001AAAAAA',
            'CreatedDate' => '2026-05-25T08:30:00Z', 'LastModifiedDate' => '2026-05-26T10:15:00Z' },
          { 'Id' => '500RM0000002AAAAAA', 'CaseNumber' => '00001002',
            'Subject' => 'Claims 837 file rejected by clearinghouse', 'Status' => 'Escalated',
            'Priority' => 'High', 'AccountId' => '001RM0000005AAAAAA',
            'ContactId' => '003RM0000006AAAAAA', 'OwnerId' => '005RM0000004DDDDDD',
            'CreatedDate' => '2026-05-30T14:05:00Z', 'LastModifiedDate' => '2026-06-02T09:00:00Z' },
          { 'Id' => '500RM0000003AAAAAA', 'CaseNumber' => '00001003',
            'Subject' => 'Patient portal SSO login failures', 'Status' => 'New',
            'Priority' => 'Medium', 'AccountId' => '001RM0000002AAAAAA',
            'ContactId' => '003RM0000003AAAAAA', 'OwnerId' => '005RM0000002BBBBBB',
            'CreatedDate' => '2026-06-05T11:50:00Z', 'LastModifiedDate' => '2026-06-05T11:50:00Z' },
          { 'Id' => '500RM0000004AAAAAA', 'CaseNumber' => '00001004',
            'Subject' => 'FHIR API returning 500 on appointment fetch', 'Status' => 'Closed',
            'Priority' => 'Low', 'AccountId' => '001RM0000004AAAAAA',
            'ContactId' => '003RM0000005AAAAAA', 'OwnerId' => '005RM0000001AAAAAA',
            'CreatedDate' => '2026-04-10T09:25:00Z', 'LastModifiedDate' => '2026-04-22T16:40:00Z' },
          { 'Id' => '500RM0000005AAAAAA', 'CaseNumber' => '00001005',
            'Subject' => 'Eligibility check timing out', 'Status' => 'Working',
            'Priority' => 'Medium', 'AccountId' => '001RM0000006AAAAAA',
            'ContactId' => '003RM0000007AAAAAA', 'OwnerId' => '005RM0000003CCCCCC',
            'CreatedDate' => '2026-05-18T13:10:00Z', 'LastModifiedDate' => '2026-05-21T08:55:00Z' }
        ]
      }
    end
  }
}
