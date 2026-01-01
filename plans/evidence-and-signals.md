# Evidence Spans & Signal Modeling

## Evidence Spans

### Predictions over Health Data
Add evidence spans to understand how the model makes predictions based on health data. This will help trace which data points influenced specific insights and suggestions.

### UI Decision Making
Add evidence spans to track the reasoning behind UI decisions - why certain components were chosen, how layouts were determined, and what drove the presentation choices.

## Signal Modeling

### Garmin Data Signals
Model signals coming from Garmin data:
- Detect when new data arrives
- Evaluate if there's anything of value to show the user
- Trigger appropriate UI updates based on data significance

### User Activity Signals
Model signals from user behavior to optimize engagement:
- Page landing events
- Wait time / time since last interaction
- Last meaningful notification timing
- Interaction patterns:
  - Scroll behavior
  - Click patterns
  - Session length
  - Active engagement vs idling
