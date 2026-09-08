# Heavy processing boundary — planned

No worker service is running in this milestone. The next milestone must define a durable queue with leased jobs, retries, idempotency and cancellation before enabling uploads. Workers receive job IDs, fetch authorized signed input, validate file signatures/archive limits, process in isolated temporary directories, validate/transform geometry and commit output with lineage. Service credentials remain in worker secrets.

AI providers return recommendations and calibrated confidence with model/version/source references. They must never bypass review or directly resolve issues. Heavy GIS/imagery work must not run inside ordinary Vercel request handlers.
