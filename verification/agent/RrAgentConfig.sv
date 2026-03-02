/**
 * @file RrAgentConfig.sv
 * @brief Round-Robin Arbiter Agent Configuration
 *
 * Configuration object for RrReqAgent. Set via uvm_config_db.
 * Allows runtime control of agent behavior.
 *
 * Usage:
 *   RrAgentConfig cfg = new("cfg");
 *   cfg.is_active = UVM_ACTIVE;
 *   cfg.has_coverage = 1;
 *   uvm_config_db#(RrAgentConfig)::set(this, "m_req_agent", "m_cfg", cfg);
 */

class RrAgentConfig extends uvm_object;

  // ---------------------------------------------------------------------------
  // Configuration Fields (must be before uvm_field macros)
  // ---------------------------------------------------------------------------

  // Active/passive mode
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Enable functional coverage collection in monitor
  bit has_coverage = 1;

  // Monitor sampling: 1 = every cycle, 0 = only on gnt change
  bit sample_every_cycle = 1;

  // ---------------------------------------------------------------------------
  // UVM Factory Registration
  // ---------------------------------------------------------------------------
  `uvm_object_utils_begin(RrAgentConfig)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_field_int(has_coverage, UVM_ALL_ON)
    `uvm_field_int(sample_every_cycle, UVM_ALL_ON)
  `uvm_object_utils_end

  // Virtual interface handle (optional - can also use config_db directly)
  // Leaving this out since interface is set separately via config_db

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  function new(string name = "RrAgentConfig");
    super.new(name);
  endfunction

endclass : RrAgentConfig
