ongoing_builds("first", meta_data={"environment": "stable"})

def ongoing_builds(pipeline: str, meta_data: Optional[dict[str, str]] = None) -> Sequence[dict]:

    return [
        build
        for build in (builds_with_state(pipeline, ["running", "failing", "blocked"], meta_data))
        if build["env"].get("PIPELINE_CONCURRENCY_ID", "") == ""
    ]

def builds_with_state(
    pipeline: str, states: list[str], meta_data: Optional[dict[str, str]] = None
) -> Iterable[dict]:

    query_params: dict[str, Union[str, list[str]]] = {"state[]": states}
    if meta_data:
        for key, value in meta_data.items():
            query_params[f"meta_data[{key}]"] = value

    return get_builds(pipeline, query_params=query_params)

def get_builds(pipeline_slug: str, query_params: Optional[dict] = None) -> list[dict]:

    try:
        builds = api_get(f"{pipeline_slug}/builds", query_params=query_params)

        assert isinstance(builds, list)
        return builds
    except HTTPError as e:
        if e.response.status_code == 404:
            raise BuildsNotFoundError(e)
        raise

BASE_URL = "<https://api.buildkite.com/v2/organizations/benchling>"

BASE_PIPELINES_URL = f"{BASE_URL}/pipelines"

def api_get(
    endpoint: str, query_params: Optional[dict] = None, headers: Optional[dict] = None
) -> Union[dict, list]:

    if headers is None:
        headers = buildkite_access_token_authorization_header()

    url = f"{BASE_PIPELINES_URL}/{endpoint}"
    if query_params:
        query_params_encoded = urlencode(query_params, doseq=True, safe="[]")
        url = f"{url}?{query_params_encoded}"
    request = Request(url=url, headers=headers, method="GET")
    return _api_call(request)

@retry(BuildkiteApiRetryException, delay=API_RETRY_DELAY, jitter=API_RETRY_JITTER, tries=API_MAX_ATTEMPTS)
def _api_call(request: Request) -> Union[dict, list]:

    prepared_request = request.prepare()
    session = _session()
    response = session.send(prepared_request)
    try:
        response.raise_for_status()
    except HTTPError as e:
        if 500 <= e.response.status_code <= 599:
            print(
                f"Got retryable http code {e.response.status_code}. Raising retryable error.", file=sys.stderr
            )
            raise BuildkiteApiRetryException()
        raise

    return response.json()

@functools.lru_cache
def _session():
    return requests.session()
