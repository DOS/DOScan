# SPDX-License-Identifier: LicenseRef-Blockscout
defmodule BlockScoutWeb.RobotsControllerTest do
  use BlockScoutWeb.ConnCase

  describe "GET robots.txt" do
    test "returns 200 with text/plain content type and sitemap reference", %{conn: conn} do
      conn = get(conn, "/robots.txt")

      assert response_content_type(conn, :plain) =~ "text/plain"
      body = response(conn, 200)
      assert body =~ "Sitemap:"
      assert body =~ "LLM Context:"
    end
  end

  describe "GET ads.txt" do
    test "returns 200 with default template when no override is set", %{conn: conn} do
      conn = get(conn, "/ads.txt")

      assert response_content_type(conn, :plain) =~ "text/plain"
      body = response(conn, 200)
      assert body =~ "# ads.txt"
      assert body =~ "ADS_TXT_CONTENT"
    end

    test "returns custom content when configured via application env", %{conn: conn} do
      original_config = Application.get_env(:block_scout_web, :ads_txt)

      on_exit(fn ->
        Application.put_env(:block_scout_web, :ads_txt, original_config)
      end)

      Application.put_env(:block_scout_web, :ads_txt,
        content: "google.com, pub-1234567890123456, DIRECT, f08c47fec0942fa0"
      )

      conn = get(conn, "/ads.txt")
      assert response_content_type(conn, :plain) =~ "text/plain"
      body = response(conn, 200)
      assert body == "google.com, pub-1234567890123456, DIRECT, f08c47fec0942fa0"
    end
  end

  describe "GET llms.txt" do
    test "returns 200 with markdown/plain content and core links", %{conn: conn} do
      conn = get(conn, "/llms.txt")

      assert response_content_type(conn, :plain) =~ "text/plain"
      body = response(conn, 200)
      assert body =~ "Explorer"
      assert body =~ "/api-docs"
      assert body =~ "/graphiql"
      assert body =~ "/verified-contracts"
    end

    test "returns custom content when configured via application env", %{conn: conn} do
      original_config = Application.get_env(:block_scout_web, :llms_txt)

      on_exit(fn ->
        Application.put_env(:block_scout_web, :llms_txt, original_config)
      end)

      Application.put_env(:block_scout_web, :llms_txt,
        content: "# Custom LLM Context\n> Custom description"
      )

      conn = get(conn, "/llms.txt")
      assert response_content_type(conn, :plain) =~ "text/plain"
      body = response(conn, 200)
      assert body == "# Custom LLM Context\n> Custom description"
    end
  end

  describe "GET llms-full.txt" do
    test "returns 200 with full technical guide for LLMs", %{conn: conn} do
      conn = get(conn, "/llms-full.txt")

      assert response_content_type(conn, :plain) =~ "text/plain"
      body = response(conn, 200)
      assert body =~ "Full Documentation for LLMs"
      assert body =~ "/api/v2/blocks"
      assert body =~ "/api/v2/transactions"
      assert body =~ "/graphql"
    end
  end
end
