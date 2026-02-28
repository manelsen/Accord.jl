using Accord
using JSON3

const DEFAULT_FIXTURES_DIR = joinpath(@__DIR__, "fixtures")

function _read_json_dict(path::AbstractString)
    return JSON3.read(read(path, String), Dict{String, Any})
end

function _read_nonempty_lines(path::AbstractString)
    lines = String[]
    for line in eachline(path)
        text = strip(line)
        isempty(text) && continue
        startswith(text, "#") && continue
        push!(lines, text)
    end
    return sort(unique(lines))
end

function _as_string_vec(value)::Vector{String}
    return sort(String[string(v) for v in value])
end

function _ensure_prefix(categories::Vector{String}, prefix::String)
    return sort([c for c in categories if startswith(c, prefix)])
end

function evaluate_fixture_coverage(fixtures_dir::AbstractString=DEFAULT_FIXTURES_DIR)
    errors = String[]
    warnings = String[]

    isdir(fixtures_dir) || error("Fixtures directory not found: $fixtures_dir")

    policy_path = joinpath(fixtures_dir, "_coverage_policy.json")
    isfile(policy_path) || error("Coverage policy not found: $policy_path")
    policy = _read_json_dict(policy_path)

    known_events_file = get(policy, "known_gateway_events_file", "_known_gateway_events.txt")
    known_events_path = joinpath(fixtures_dir, known_events_file)
    isfile(known_events_path) || error("Known events file not found: $known_events_path")
    expected_gateway_events = _read_nonempty_lines(known_events_path)

    manifest_file = get(policy, "manifest_file", "_manifest.json")
    manifest_path = joinpath(fixtures_dir, manifest_file)
    isfile(manifest_path) || error("Manifest not found: $manifest_path")
    manifest = _read_json_dict(manifest_path)

    required_gateway = _as_string_vec(get(policy, "required_gateway_fixtures", Any[]))
    required_rest = _as_string_vec(get(policy, "required_rest_fixtures", Any[]))
    allowed_non_dispatch_gateway = Set(_as_string_vec(get(policy, "allowed_non_dispatch_gateway_fixtures", Any[])))

    fixture_categories = sort([
        replace(file, r"\.json$" => "")
        for file in readdir(fixtures_dir)
        if endswith(file, ".json") && !startswith(file, "_")
    ])
    manifest_categories = _as_string_vec(get(manifest, "categories", Any[]))

    gateway_fixtures = _ensure_prefix(fixture_categories, "gateway_")
    rest_fixtures = _ensure_prefix(fixture_categories, "rest_")

    missing_required_gateway = setdiff(required_gateway, gateway_fixtures)
    isempty(missing_required_gateway) || push!(
        errors,
        "Missing required gateway fixture categories: $(join(missing_required_gateway, ", "))",
    )

    missing_required_rest = setdiff(required_rest, rest_fixtures)
    isempty(missing_required_rest) || push!(
        errors,
        "Missing required REST fixture categories: $(join(missing_required_rest, ", "))",
    )

    missing_in_manifest = setdiff(fixture_categories, manifest_categories)
    isempty(missing_in_manifest) || push!(
        errors,
        "Fixtures present on disk but missing in manifest: $(join(missing_in_manifest, ", "))",
    )

    missing_on_disk = setdiff(manifest_categories, fixture_categories)
    isempty(missing_on_disk) || push!(
        errors,
        "Fixtures listed in manifest but missing on disk: $(join(missing_on_disk, ", "))",
    )

    current_gateway_events = sort(collect(keys(Accord.EVENT_TYPES)))
    added_gateway_events = setdiff(current_gateway_events, expected_gateway_events)
    removed_gateway_events = setdiff(expected_gateway_events, current_gateway_events)

    isempty(added_gateway_events) || push!(
        errors,
        "New gateway events were added to EVENT_TYPES without baseline update: $(join(added_gateway_events, ", "))",
    )
    isempty(removed_gateway_events) || push!(
        errors,
        "Gateway events were removed/renamed from EVENT_TYPES baseline: $(join(removed_gateway_events, ", "))",
    )

    covered_gateway_events = String[]
    for category in gateway_fixtures
        event_name = uppercase(replace(category, "gateway_" => ""))
        if event_name in current_gateway_events
            push!(covered_gateway_events, event_name)
            continue
        end

        category in allowed_non_dispatch_gateway && continue
        push!(
            errors,
            "Gateway fixture category '$category' does not map to EVENT_TYPES and is not allowed as non-DISPATCH fixture.",
        )
    end

    covered_gateway_events = sort(unique(covered_gateway_events))
    uncovered_gateway_events = setdiff(current_gateway_events, covered_gateway_events)
    if !isempty(uncovered_gateway_events)
        preview = first(uncovered_gateway_events, min(12, length(uncovered_gateway_events)))
        suffix = length(uncovered_gateway_events) > length(preview) ? ", ..." : ""
        push!(
            warnings,
            "Gateway fixture coverage is $(length(covered_gateway_events))/$(length(current_gateway_events)) events. Missing: $(join(preview, ", "))$suffix",
        )
    end

    coverage_pct = isempty(current_gateway_events) ? 0.0 :
        round(100 * length(covered_gateway_events) / length(current_gateway_events), digits=2)

    return (
        ok = isempty(errors),
        errors = errors,
        warnings = warnings,
        stats = (
            fixtures_dir = fixtures_dir,
            fixture_categories = fixture_categories,
            manifest_categories = manifest_categories,
            gateway_fixtures = gateway_fixtures,
            rest_fixtures = rest_fixtures,
            gateway_event_total = length(current_gateway_events),
            gateway_event_covered = length(covered_gateway_events),
            gateway_event_uncovered = uncovered_gateway_events,
            gateway_coverage_pct = coverage_pct,
        ),
    )
end

function print_fixture_coverage_report(result; io::IO=stdout)
    stats = result.stats
    println(io, "Fixture Coverage Report")
    println(io, "  Directory: $(stats.fixtures_dir)")
    println(io, "  Fixtures on disk: $(length(stats.fixture_categories))")
    println(io, "  Gateway fixtures: $(length(stats.gateway_fixtures))")
    println(io, "  REST fixtures: $(length(stats.rest_fixtures))")
    println(io, "  Gateway event coverage: $(stats.gateway_event_covered)/$(stats.gateway_event_total) ($(stats.gateway_coverage_pct)%)")

    if !isempty(result.errors)
        println(io, "Errors:")
        for msg in result.errors
            println(io, "  - $msg")
        end
    end

    if !isempty(result.warnings)
        println(io, "Warnings:")
        for msg in result.warnings
            println(io, "  - $msg")
        end
    end
end

function run_fixture_coverage_check(fixtures_dir::AbstractString=DEFAULT_FIXTURES_DIR; io::IO=stdout)
    result = evaluate_fixture_coverage(fixtures_dir)
    print_fixture_coverage_report(result; io=io)
    return result
end
