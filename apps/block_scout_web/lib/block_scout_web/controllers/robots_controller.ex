# SPDX-License-Identifier: LicenseRef-Blockscout
defmodule BlockScoutWeb.RobotsController do
  use BlockScoutWeb, :controller

  def robots(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> render("robots.txt")
  end

  def sitemap(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> render("sitemap.xml")
  end

  def ads(conn, _params) do
    case get_file_or_content_override(:ads_txt) do
      {:ok, content} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, content)

      :default ->
        conn
        |> put_resp_content_type("text/plain")
        |> render("ads.txt")
    end
  end

  def llms(conn, _params) do
    case get_file_or_content_override(:llms_txt) do
      {:ok, content} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, content)

      :default ->
        conn
        |> put_resp_content_type("text/plain")
        |> render("llms.txt")
    end
  end

  def llms_full(conn, _params) do
    case get_file_or_content_override(:llms_full_txt) do
      {:ok, content} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, content)

      :default ->
        conn
        |> put_resp_content_type("text/plain")
        |> render("llms_full.txt")
    end
  end

  defp get_file_or_content_override(config_key) do
    config = Application.get_env(:block_scout_web, config_key, [])
    content = config[:content]
    file_path = config[:file_path]

    cond do
      is_binary(content) and byte_size(String.trim(content)) > 0 ->
        {:ok, content}

      is_binary(file_path) and byte_size(String.trim(file_path)) > 0 and File.exists?(file_path) ->
        case File.read(file_path) do
          {:ok, file_content} -> {:ok, file_content}
          _ -> :default
        end

      true ->
        :default
    end
  end
end
