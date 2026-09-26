# SPDX-License-Identifier: LicenseRef-Blockscout
defmodule BlockScoutWeb.RobotsView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.{APIDocsView, LayoutView}
  alias Explorer
  alias Explorer.{Chain, PagingOptions}
  alias Explorer.Chain.{Address, Token}

  @limit 50
  defp limit, do: @limit

  def host, do: APIDocsView.blockscout_url(true)

  def subnetwork_title, do: LayoutView.subnetwork_title()

  def network_title, do: LayoutView.network_title()

  def coin, do: Explorer.coin()
end
