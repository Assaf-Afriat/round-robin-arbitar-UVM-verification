# Round-Robin Arbiter – Compact Spec

N requesters → 1 grant. Fair, starvation-free arbitration.

## Interface


| Signal      | Direction | Width | Description                     |
| ----------- | --------- | ----- | ------------------------------- |
| `clk`       | input     | 1     | Clock                           |
| `rst_n`     | input     | 1     | Active-low reset                |
| `req`   | input  | N     | Request vector (1 = request)    |
| `gnt`   | output | N     | Grant vector (1-hot, 1 = grant) |


## Parameters

| Param         | Default | Description                                      |
| ------------- | ------- | ------------------------------------------------ |
| `N`           | 4       | Number of requesters                             |
| `MAX_HOLD_CYC`| 64      | Max cycles one requester can hold grant; prevents starvation |

## Behavior

- **Round-robin**: If requester i is granted, next priority is i+1, i+2, …, wrapping to 0.
- **Fairness**: No starvation; each requester gets a turn when it asserts `req`.
- **Max hold**: If a requester holds `req` for `MAX_HOLD_CYC` consecutive cycles, arbiter forces re-arbitration and grants the next requester in round-robin order.
- **Single grant**: Exactly one `gnt` bit asserted when any `req` is high; otherwise `gnt` is all zeros.
- **Reset**: Async active-low; after reset, first priority = requester 0.
- **Registered gnt**: Grant appears 1 cycle after arbitration; not combinatorial.
- **Handshake**: Requester holds `req` until done; arbiter holds `gnt` until `req` drops. Re-arbitrates when `|gnt == 0` or `(gnt & req) == 0`.

## UVM Value

- Scoreboarding: reference model predicts grant based on last winner + req vector.
- Sequence variants: back-to-back requests, idle cycles, all-request patterns.
- Coverage: request combinations, last-grant → next-grant transitions.

