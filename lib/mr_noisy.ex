defmodule MrNoisy do
  @moduledoc """
  Documentation for MrNoisy.
  """

  @doc """
  Hello world.

  ## Examples

      iex> MrNoisy.hello
      :world

  """
  def start(_type, _args) do
    do_it()
  end

  def do_it do
    System.get_env("PROJECT_ID_LIST")
    |> String.split(",")
    |> get_open_merge_requests_from_gitlab
    |> Enum.sort_by(&(Map.get(&1, "created_at")))
    |> format_message_list
    |> format_list_to_single_message
    |> post_to_slack
  end

  def get_open_merge_requests_from_gitlab([x | y]) do
    header = [
      "Private-Token": System.get_env("GITLAB_TOKEN")
    ]
    options = [
      params: %{
        state: "opened",
        labels: "Review Me",
        order_by: "created_at",
        sort: "asc",
        per_page: 100,
      }
    ]

    HTTPoison.get("https://gitlab.gds-gov.tech/api/v4/projects/#{x}/merge_requests", header, options)
    |> convert_gitlab_api_response
    |> Kernel.++(get_open_merge_requests_from_gitlab(y))
  end

  def get_open_merge_requests_from_gitlab([]) do
    []
  end

  def convert_gitlab_api_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    body
    |> Poison.decode!
  end

  def convert_gitlab_api_response(_) do
    IO.puts "Error fetching from gitlab"
    []
  end

  def format_message_list([x | y]) do
    title = Map.get(x, "title", "")
    web_url = Map.get(x, "web_url", "")
    updated_at = Map.get(x, "updated_at", "")
    created_at = Map.get(x, "created_at", "")
    {:ok, converted_created_time, _} = DateTime.from_iso8601 created_at
    {:ok, converted_updated_time, _} = DateTime.from_iso8601 updated_at
    created_time_difference = parse_datetime_difference(converted_created_time)
    updated_time_difference = parse_datetime_difference(converted_updated_time)
    message = "> <#{web_url}|#{title}>\n> _(Updated #{updated_time_difference} ago) (Opened #{created_time_difference} ago)_"

    [message |format_message_list(y)]
  end

  def format_message_list([]) do
    []
  end

  def parse_datetime_difference(datetime) do
    difference = DateTime.diff(DateTime.utc_now, datetime)
    cond do
      difference > 86400 ->
        trunc(difference/86400)
        |> append_datetime_unit("day")
      difference > 3600 ->
        trunc(difference/3600)
        |> append_datetime_unit("hour")
      difference > 60 ->
        trunc(difference/60)
        |> append_datetime_unit("minute")
      true ->
        trunc(difference)
        |> append_datetime_unit("second")
    end
  end

  def append_datetime_unit(value, single_unit) when value > 1 do
    "#{value} #{single_unit}s"
  end

  def append_datetime_unit(value, single_unit) do
    "#{value} #{single_unit}"
  end

  def format_list_to_single_message(message_list) do
    message_prefix = "<!channel>\n*#{length(message_list)} Merge Requests awaiting review:*"
    "#{message_prefix}\n#{Enum.join(message_list, "\n\n")}"
  end

  def post_to_slack(message) do
    channel_id = System.get_env("CHANNEL")
    header = [
      "Authorization": "Bearer #{System.get_env("SLACK_TOKEN")}",
      "Content-type": "application/json; charset=utf-8"
    ]
    body = "{\"channel\":\"#{channel_id}\", \"text\": \"#{message}\"}"

    HTTPoison.post "https://slack.com/api/chat.postMessage", body, header
  end
end
