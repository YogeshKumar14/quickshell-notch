#!/usr/bin/env python3
"""
tests/test_e2e.py — Pytest Interface for Authentic E2E Integration Suite.

Exposes the 59 authentic integration test cases from scripts/core/e2e_test_suite.py
for standard test discovery tools (pytest, python -m unittest).
"""

import sys
from pathlib import Path

# Add project root and scripts directory to sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))
SCRIPTS_CORE = BASE_DIR / "scripts" / "core"
if str(SCRIPTS_CORE) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_CORE))

from e2e_test_suite import (
    # Tier 1
    test_t1_pipewire_sink_volume_query,
    test_t1_pipewire_source_volume_query,
    test_t1_pipewire_status_sinks_listing,
    test_t1_pipewire_status_sources_listing,
    test_t1_pipewire_manage_audio_schema,
    test_t1_pipewire_volume_step_and_restore,
    test_t1_dbus_notification_dispatch,
    test_t1_dbus_notification_markup_support,
    test_t1_dbus_mpris_service_discovery,
    test_t1_dbus_mpris_metadata_query,
    test_t1_dbus_mpris_seek_engine_integration,
    test_t1_dbus_mpris_duration_resolution,
    test_t1_cava_streamer_json_contract,
    test_t1_cava_streamer_bar_count_conformity,
    test_t1_cava_streamer_amplitude_range,
    test_t1_cava_streamer_config_generation,
    test_t1_cava_streamer_deadband_filtering,
    test_t1_cava_streamer_sigterm_cleanup,
    test_t1_hyprland_ipc_connection,
    test_t1_hyprland_lua_file_syntax,
    test_t1_hyprland_lua_table_structure,
    test_t1_hyprland_color_normalization_and_swap,
    test_t1_hyprland_apply_hypr_option_fallback,
    test_t1_hyprland_atomic_batch_settings_writer,
    test_t1_ipc_socket_connectivity,
    test_t1_ipc_navigation_commands,
    test_t1_ipc_drawer_toggles,
    test_t1_ipc_value_commands,
    test_t1_ipc_macro_lifecycle_commands,
    test_t1_ipc_client_exit_code_propagation,
    # Tier 2
    test_t2_bva_osd_volume_negative,
    test_t2_bva_osd_volume_upper_boundary,
    test_t2_bva_osd_volume_overflow,
    test_t2_bva_osd_brightness_negative,
    test_t2_bva_osd_brightness_upper_boundary,
    test_t2_bva_osd_brightness_overflow,
    test_t2_bva_tab_index_negative,
    test_t2_bva_tab_index_out_of_bounds,
    test_t2_bva_tab_index_non_numeric,
    test_t2_bva_settings_tab_out_of_bounds,
    test_t2_bva_ipc_payload_with_null_bytes,
    test_t2_bva_ipc_oversized_payload,
    test_t2_bva_cava_bar_count_clamping,
    test_t2_bva_color_normalization_edge_cases,
    test_t2_bva_rapid_socket_connect_disconnect_burst,
    # Tier 3
    test_t3_pairwise_cava_streaming_and_tab_switching,
    test_t3_pairwise_volume_osd_during_expanded_nook,
    test_t3_pairwise_ipc_toggle_burst_during_notification,
    test_t3_pairwise_drawer_mutual_exclusion_cascade,
    test_t3_pairwise_settings_reload_during_notch_expand,
    test_t3_pairwise_rapid_ipc_morphing_burst,
    test_t3_pairwise_pipewire_mute_and_device_levels_query,
    test_t3_pairwise_mpris_seek_during_cava_active,
    # Tier 4
    test_t4_realworld_full_user_desktop_workflow,
    test_t4_realworld_100_rapid_ipc_storm,
    test_t4_realworld_notification_flood_and_staggered_clear,
    test_t4_realworld_sustained_cava_streaming_memory_stability,
    test_t4_realworld_process_lifecycle_reaper_verification,
    test_t4_realworld_settings_batch_persistence_roundtrip,
)
