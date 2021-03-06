defmodule Magnetissimo.DownloadWorker do
  alias Magnetissimo.Torrent
  require Logger

  def download("https://" <> _ = url), do: safe_download(url)
  def download("http://" <> _ = url), do: safe_download(url)

  def download(url), do: Logger.debug "Ignoring #{url}"

  defp safe_download(url) do
    case HTTPoison.get(url, [], [follow_redirect: true]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, status}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  # EZTV workers.
  def perform(url, "eztv", "root_url") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        Magnetissimo.Parsers.EZTV.paginated_links(body)
        |> Enum.each(fn url ->
          Exq.enqueue(Exq, "eztv", "Magnetissimo.DownloadWorker", [url, "eztv", "paginated_links"])
        end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "eztv", "paginated_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        Magnetissimo.Parsers.EZTV.torrent_links(body)
        |> Enum.each(fn url ->
          Exq.enqueue(Exq, "eztv", "Magnetissimo.DownloadWorker", [url, "eztv", "torrent_links"])
        end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "eztv", "torrent_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        case Magnetissimo.Parsers.EZTV.scrape_torrent_information(body) do
          {:ok, torrent} ->
            Logger.debug inspect torrent
            Torrent.save_torrent(torrent)
          _ -> nil
        end
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  # Leetx workers.
  def perform(url, "leetx", "root_url") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        pages = Magnetissimo.Parsers.Leetx.paginated_links(body)
        pages
      |> Enum.each(fn url ->
        Exq.enqueue(Exq, "leetx", "Magnetissimo.DownloadWorker", [url, "leetx", "paginated_links"])
      end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "leetx", "paginated_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        torrent_links = Magnetissimo.Parsers.Leetx.torrent_links(body)
        torrent_links
      |> Enum.each(fn url ->
        Exq.enqueue(Exq, "leetx", "Magnetissimo.DownloadWorker", [url, "leetx", "torrent_links"])
      end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "leetx", "torrent_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        torrent = Magnetissimo.Parsers.Leetx.scrape_torrent_information(body)
        Logger.debug inspect torrent
        Torrent.save_torrent(torrent)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  # ThePirateBay workers.
  def perform(url, "thepiratebay", "root_url") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        Magnetissimo.Parsers.ThePirateBay.paginated_links(body)
      |> Enum.each(fn url ->
        Exq.enqueue(Exq, "thepiratebay", "Magnetissimo.DownloadWorker", [url, "thepiratebay", "paginated_links"])
      end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "thepiratebay", "paginated_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        Magnetissimo.Parsers.ThePirateBay.torrent_links(body)
        |> Enum.each(fn url ->
          Exq.enqueue(Exq, "thepiratebay", "Magnetissimo.DownloadWorker", [url, "thepiratebay", "torrent_links"])
        end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "thepiratebay", "torrent_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        torrent = Magnetissimo.Parsers.ThePirateBay.scrape_torrent_information(body)
        Logger.debug inspect torrent
        Torrent.save_torrent(torrent)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  # Demonoid workers.
  def perform(url, "demonoid", "root_url") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        Magnetissimo.Parsers.Demonoid.paginated_links(body)
        |> Enum.each(fn url ->
          Logger.debug url
          Exq.enqueue(Exq, "demonoid", "Magnetissimo.DownloadWorker", [url, "demonoid", "paginated_links"])
        end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "demonoid", "paginated_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        torrent_links = Magnetissimo.Parsers.Demonoid.torrent_links(body)
        torrent_links
      |> Enum.each(fn url ->
        Exq.enqueue(Exq, "demonoid", "Magnetissimo.DownloadWorker", [url, "demonoid", "torrent_links"])
      end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "demonoid", "torrent_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        torrent = Magnetissimo.Parsers.Demonoid.scrape_torrent_information(body)
        Logger.debug inspect torrent
        Torrent.save_torrent(torrent)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  # Isohunt workers.
  def perform(url, "isohunt", "root_url") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        Magnetissimo.Parsers.Isohunt.paginated_links(body)
        |> Enum.each(fn url ->
          Exq.enqueue(Exq, "isohunt", "Magnetissimo.DownloadWorker", [url, "isohunt", "paginated_links"])
        end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "isohunt", "paginated_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        Magnetissimo.Parsers.Isohunt.torrent_links(body)
        |> Enum.each(fn url ->
          Exq.enqueue(Exq, "isohunt", "Magnetissimo.DownloadWorker", [url, "isohunt", "torrent_links"])
        end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "isohunt", "torrent_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        torrent = Magnetissimo.Parsers.Isohunt.scrape_torrent_information(body)
        Logger.debug inspect torrent
        Torrent.save_torrent(torrent)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  # Limetorrents workers.
  def perform(url, "limetorrents", "root_url") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        pages = Magnetissimo.Parsers.Limetorrents.paginated_links(body)
        pages
      |> Enum.each(fn url ->
        Exq.enqueue(Exq, "limetorrents", "Magnetissimo.DownloadWorker", [url, "limetorrents", "paginated_links"])
      end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "limetorrents", "paginated_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        torrent_links = Magnetissimo.Parsers.Limetorrents.torrent_links(body)
        torrent_links
      |> Enum.each(fn url ->
        Exq.enqueue(Exq, "limetorrents", "Magnetissimo.DownloadWorker", [url, "limetorrents", "torrent_links"])
      end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "limetorrents", "torrent_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        torrent = Magnetissimo.Parsers.Limetorrents.scrape_torrent_information(body)
        Logger.debug inspect torrent
        Torrent.save_torrent(torrent)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  # Torrentdownload workers.
  def perform(url, "torrentdownloads", "root_url") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        Magnetissimo.Parsers.TorrentDownloads.paginated_links(body)
        |> Enum.each(fn url ->
          Exq.enqueue(Exq, "torrentdownloads", "Magnetissimo.DownloadWorker", [url, "torrentdownloads", "paginated_links"])
        end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "torrentdownloads", "paginated_links") do
    Logger.debug "Crawling: #{url}"
    case download(url) do
      {:ok, body} ->
        Magnetissimo.Parsers.TorrentDownloads.torrent_links(body)
        |> Enum.each(fn url ->
          Exq.enqueue(Exq, "torrentdownloads", "Magnetissimo.DownloadWorker", [url, "torrentdownloads", "torrent_links"])
        end)
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

  def perform(url, "torrentdownloads", "torrent_links") do
    Logger.debug "Crawling: torrent_links #{url}"
    case download(url) do
      {:ok, body} ->
        case Magnetissimo.Parsers.TorrentDownloads.scrape_torrent_information(body) do
          torrent when is_map(torrent) ->
            Torrent.save_torrent(torrent)
          _ -> nil
        end
      {:error, reason} ->
        Logger.info "Failed downloading url:#{url} reason:#{reason}"
    end
  end

end
