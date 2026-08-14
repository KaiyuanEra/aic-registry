# Resource Config Presets

## Standard Presets

| Service size | CPU limits | CPU requests | Memory limits | Memory requests | Use case |
|----------|------------|--------------|---------------|-----------------|----------|
| Small | 500m | 200m | 1Gi | 512Mi | Tool services, low-traffic APIs |
| Medium | 1000m | 600m | 3Gi | 2Gi | Standard business services |
| Large | 2000m | 1000m | 6Gi | 4Gi | High-concurrency, compute-intensive services |

## Selection Advice

**Small (500m/1Gi):**
- Internal tools, admin dashboards
- Daily requests < 100k
- No complex computation logic

**Medium (1000m/3Gi):**
- Standard business API services
- Daily requests 100k to 1M
- Has database queries, cache operations

**Large (2000m/6Gi):**
- Core business services, gateways
- Daily requests > 1M
- Has heavy concurrency, data processing

## requests vs limits Explanation

- `requests`: resources guaranteed at scheduling time; affects which node the Pod is scheduled to
- `limits`: resource cap for the container; exceeding CPU limits causes throttling, exceeding Memory limits causes OOM Kill
- Recommend requests at 40% to 60% of limits to avoid waste while preserving elasticity
