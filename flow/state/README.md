# MCP state (*.state.json) + actions.jsonl for AI Design IDE discovery.

`magpie_m1.isa_scope.state.json` is the active scope record for
`gate_00_spec`. It records ADR-0001 as superseded-for-implementation, ADR-0002
as accepted, and Ch2 `lab08e` `RV32IMC_Zicsr_Zifencei` 4-stage pipeline + BP +
RAS + RV32C + pre-fetch as the active Magpie_M1 productization line.

Note: platform `pipeline.record_step` currently validates stages against a
fixed SoC list that does not include `isa_scope`, so this state was emitted
manually for transparency. The platform schema should add CPU IP development
stages before this becomes a fully automated record_step path.
