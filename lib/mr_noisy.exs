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

  def do_it do
    System.get_env("PROJECT_ID_LIST")
    |> String.split(",")
    |> get_open_merge_requests_from_gitlab
    |> Enum.reject(&has_bot_label/1)
    |> Enum.sort_by(&(Map.get(&1, "created_at")))
    |> format_message_list
    |> post_to_messaging_clients
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

  def has_bot_label(list) do
    list
    |> Map.get("labels")
    |> Enum.member?("Bot")
  end

  def convert_gitlab_api_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    body
    |> Poison.decode!
  end

  def convert_gitlab_api_response(_) do
    IO.puts "Error fetching from gitlab"
    []
  end

  def format_message_list(list) do
    messages_for_slack = format_message_list_for_slack(list)
    message_prefix_for_slack = "<!channel>\n*#{length(messages_for_slack)} Merge Requests awaiting review:*"
    messages_for_telegram = format_message_list_for_telegram(list)
    message_prefix_for_telegram = "*#{length(messages_for_telegram)} Merge Requests awaiting review:*"

    %{
      slack: "#{message_prefix_for_slack}\n#{Enum.join(messages_for_slack, "\n\n")}",
      telegram: "#{message_prefix_for_telegram}\n#{Enum.join(messages_for_telegram, "\n\n")}"
    }
  end

  # def format_message_list([]) do
  #   %{slack: [], telegram: []}
  # end

  def format_message_list_for_telegram([x | y]) do
    title = Map.get(x, "title", "")
      |> String.replace("[", "")
      |> String.replace("]", "")
    web_url = Map.get(x, "web_url", "")
    updated_at = Map.get(x, "updated_at", "")
    created_at = Map.get(x, "created_at", "")
    {:ok, converted_created_time, _} = DateTime.from_iso8601 created_at
    {:ok, converted_updated_time, _} = DateTime.from_iso8601 updated_at
    created_time_difference = parse_datetime_difference(converted_created_time)
    updated_time_difference = parse_datetime_difference(converted_updated_time)
    message = "→ [#{title}](#{web_url})\n _(Updated #{updated_time_difference} ago) (Opened #{created_time_difference} ago)_"

    [message |format_message_list_for_telegram(y)]
  end

  def format_message_list_for_telegram([]) do
    []
  end

  def format_message_list_for_slack([x | y]) do
    title = Map.get(x, "title", "")
    web_url = Map.get(x, "web_url", "")
    updated_at = Map.get(x, "updated_at", "")
    created_at = Map.get(x, "created_at", "")
    {:ok, converted_created_time, _} = DateTime.from_iso8601 created_at
    {:ok, converted_updated_time, _} = DateTime.from_iso8601 updated_at
    created_time_difference = parse_datetime_difference(converted_created_time)
    updated_time_difference = parse_datetime_difference(converted_updated_time)
    message = "> <#{web_url}|#{title}>\n> _(Updated #{updated_time_difference} ago) (Opened #{created_time_difference} ago)_"

    [message |format_message_list_for_slack(y)]
  end

  def format_message_list_for_slack([]) do
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

  def post_to_messaging_clients(%{slack: slack_message, telegram: telegram_message}) do
    post_to_slack slack_message
    post_to_telegram telegram_message
    {:ok}
  end

  def post_to_slack(message) do
    channel_id = System.get_env("SLACK_CHANNEL")
    header = [
      "Authorization": "Bearer #{System.get_env("SLACK_TOKEN")}",
      "Content-type": "application/json; charset=utf-8"
    ]
    body = "{\"channel\":\"#{channel_id}\", \"text\": \"#{message}\"}"

    HTTPoison.post "https://slack.com/api/chat.postMessage", body, header
  end

  def post_to_telegram(message) do
    telegram_group_id = System.get_env("TELEGRAM_CHANNEL")
    telegram_token = System.get_env("TELEGRAM_TOKEN")
    header = ["Content-type": "application/json; charset=utf-8"]

    body = "{" <>
      "\"chat_id\": \"#{telegram_group_id}\"," <>
      "\"text\": \"#{message}\"," <>
      "\"parse_mode\": \"markdown\"," <>
      "\"disable_web_page_preview\": true" <>
    "}"

    HTTPoison.post "https://api.telegram.org/bot#{telegram_token}/sendMessage", body, header
  end
end

MrNoisy.do_it