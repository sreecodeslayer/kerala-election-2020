defmodule Ke do
  @base_url "https://results.prdlive.trtech.in/json/"

  require Logger

  def start(skip \\ []) do
    dists = get_districts()
    dists = dists -- skip

    Enum.map(dists, fn d ->
      get_full_district(d)
      Logger.info(String.duplicate("==", 25))
    end)
  end

  def get_full_district(d, save? \\ true) do
    Logger.debug("Starting to parse district #{d}")
    all_gps = get_gram_panchs_for_dist(d)
    :timer.sleep(1000)
    all_blocks = get_block_panchs_for_dist(d)
    :timer.sleep(1000)
    all_dt_panchs = get_dist_panchs_for_dist(d)
    :timer.sleep(1000)
    all_urbans = get_urbans_for_dist(d)

    all_gps =
      Enum.map(all_gps, fn gp ->
        gp = get_gram_panch(gp)
        :timer.sleep(1000)
        gp
      end)

    Logger.info(String.duplicate("--", 25))

    all_blocks =
      Enum.map(all_blocks, fn bl ->
        bl = get_block_panch(bl)
        :timer.sleep(1000)
        bl
      end)

    Logger.info(String.duplicate("--", 25))

    all_dt_panchs =
      Enum.map(all_dt_panchs, fn dpn ->
        dpn = get_district_panch(dpn)
        :timer.sleep(1000)
        dpn
      end)

    Logger.info(String.duplicate("--", 25))

    all_urbans =
      Enum.map(all_urbans, fn ubn ->
        ubn = get_urban_body(ubn)
        :timer.sleep(1000)
        ubn
      end)

    dist = %{
      dist_code: d,
      gram_panchayats: all_gps,
      block_panchayats: all_blocks,
      district_panchayats: all_dt_panchs,
      urban_bodies: all_urbans
    }

    if save?, do: File.write("data/#{d}_data.json", Jason.encode!(dist)), else: dist
  end

  def get_districts do
    url = @base_url <> "sv2lpgl.json?_=#{ts()}"
    ds = HTTPoison.get!(url, headers(), options())
    json_data = Jason.decode!(ds.body)

    Enum.map(json_data["total"], fn [dist | _] -> dist end)
  end

  def get_gram_panchs_for_dist(dist_code) do
    Logger.debug("Fetching gram_panchayats for dist_code: #{dist_code}")
    url = @base_url <> "dvGramaLead_#{dist_code}.json?_=#{ts()}"
    dist = HTTPoison.get!(url, headers(), options())
    json_data = Jason.decode!(dist.body)

    Enum.map(json_data["payload"], &get_code_name_summary_for_body(&1))
  end

  def get_block_panchs_for_dist(dist_code) do
    Logger.debug("Fetching block_panchayats for dist_code: #{dist_code}")
    url = @base_url <> "dvBlockLead_#{dist_code}.json?_=#{ts()}"
    dist = HTTPoison.get!(url, headers(), options())
    json_data = Jason.decode!(dist.body)

    Enum.map(json_data["payload"], &get_code_name_summary_for_body(&1))
  end

  def get_dist_panchs_for_dist(dist_code) do
    Logger.debug("Fetching district_panchayats for dist_code: #{dist_code}")
    url = @base_url <> "dvDistLead_#{dist_code}.json?_=#{ts()}"
    dist = HTTPoison.get!(url, headers(), options())
    json_data = Jason.decode!(dist.body)

    Enum.map(json_data["payload"], &get_code_name_summary_for_body(&1))
  end

  def get_urbans_for_dist(dist_code) do
    Logger.debug("Fetching urban bodies for dist_code: #{dist_code}")
    url = @base_url <> "dvUrbanLead_#{dist_code}.json?_=#{ts()}"
    dist = HTTPoison.get!(url, headers(), options())
    json_data = Jason.decode!(dist.body)

    Enum.map(json_data["payload"], fn [urb_code, urb_name | _] = urb ->
      %{
        code: urb_code,
        name: String.upcase(urb_name),
        summary: get_code_name_summary_for_body(urb)
      }
    end)
  end

  def get_gram_panch(%{code: gp_code, name: name, summary: summary}) do
    Logger.debug("Fetching ward data for: #{gp_code} - #{name}")
    url = @base_url <> "#{gp_code}_L.json?_=#{ts()}"
    gp = HTTPoison.get!(url, headers())

    json_data = Jason.decode!(gp.body)

    data = Enum.map(json_data["payload"], &parse_local_body_data(&1))

    %{body: name, code: gp_code, data: data, summary: summary}
  end

  def get_block_panch(%{code: bl_code, name: name, summary: summary}) do
    Logger.debug("Fetching block data for: #{bl_code} - #{name}")
    url = @base_url <> "#{bl_code}_L.json?_=#{ts()}"

    block = HTTPoison.get!(url, headers())

    unless block.status_code == 403 do
      json_data = Jason.decode!(block.body)

      data = Enum.map(json_data["payload"], &parse_local_body_data(&1))

      %{body: name, code: bl_code, data: data, summary: summary}
    else
      Logger.error("Could not fetch due to 403 status code for #{name}")

      %{
        body: name,
        code: bl_code,
        data: "Could not fetch due to 403 status code",
        summary: summary
      }
    end
  end

  def get_urban_body(%{code: ubn_code, name: name, summary: summary}) do
    Logger.debug("Fetching urban data for: #{ubn_code} - #{name}")
    url = @base_url <> "#{ubn_code}_L.json?_=#{ts()}"

    block = HTTPoison.get!(url, headers())

    unless block.status_code == 403 do
      json_data = Jason.decode!(block.body)

      data = Enum.map(json_data["payload"], &parse_local_body_data(&1))

      %{body: name, code: ubn_code, data: data, summary: summary}
    else
      Logger.error("Could not fetch due to 403 status code for #{name}")

      %{
        body: name,
        code: ubn_code,
        data: "Could not fetch due to 403 status code",
        summary: summary
      }
    end
  end

  def get_district_panch(%{code: d_code, name: name, summary: summary}) do
    Logger.debug("Fetching dist panchayat data for: #{d_code} - #{name}")
    url = @base_url <> "#{d_code}_L.json?_=#{ts()}"
    gp = HTTPoison.get!(url, headers())

    json_data = Jason.decode!(gp.body)

    data = Enum.map(json_data["payload"], &parse_local_body_data(&1))

    %{body: name, code: d_code, data: data, summary: summary}
  end

  defp parse_local_body_data(json) do
    # Leading candidate
    w_l_party = Enum.at(json, 1)

    w_l_cn_num = Enum.at(json, 2)
    w_l_cn_name = Enum.at(String.split(Enum.at(json, 3) || "", "-", trim: true), 1)

    w_l_cn_votes = String.to_integer(Enum.at(json, 4) || "0")

    # Trailing candidate
    place_name = Enum.at(json, 5)

    w_t_cn_num = Enum.at(json, 7)
    w_t_cn_name = Enum.at(String.split(Enum.at(json, 8) || "", "-", trim: true), 1) || ""

    w_t_cn_votes = String.to_integer(Enum.at(json, 9) || "0")

    %{
      declared?: Enum.at(json, 6) == "Y",
      place: place_name,
      lead: %{
        num: w_l_cn_num,
        name: String.trim(w_l_cn_name),
        votes: w_l_cn_votes,
        party: w_l_party
      },
      trail: %{
        num: w_t_cn_num,
        name: String.trim(w_t_cn_name),
        votes: w_t_cn_votes
      }
    }
  end

  defp get_code_name_summary_for_body(body) do
    [code, name, total_wards, _, udf, ldf, bjp_, oth] = body

    s = %{
      udf: String.to_integer(udf),
      ldf: String.to_integer(ldf),
      bjp_: String.to_integer(bjp_),
      oth: String.to_integer(oth),
      wards: String.to_integer(total_wards)
    }

    %{
      code: code,
      name: String.upcase(name),
      summary: s
    }
  end

  defp headers do
    [
      {"User-Agent", Enum.random(uas())},
      {"Host", "results.prdlive.trtech.in"},
      {"Accept", "application/json"},
      {"Referer", "https://results.prdlive.trtech.in/index.html"},
      {"Connection", "keep-alive"},
      {"X-Requested-With", "XMLHttpRequest"},
      {"Pragma", "no-cache"},
      {"Accept-Language", "en-US,en;q=0.5"},
      {"Accept-Encoding", "gzip, deflate, br"},
      {"Cache-Control", "no-cache"}
    ]
  end

  defp options do
    [
      proxy: {:socks5, 'localhost', 5566},
      timeout: 15000,
      recv_timeout: 15000
    ]
  end

  defp uas do
    [
      "Mozilla/5.0 (Linux; Android 8.0.0; SM-G960F Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.84 Mobile Safari/537.36",
      "Mozilla/5.0 (Linux; Android 7.0; SM-G892A Build/NRD90M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/60.0.3112.107 Mobile Safari/537.36",
      "Mozilla/5.0 (Linux; Android 7.0; SM-G930VC Build/NRD90M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/58.0.3029.83 Mobile Safari/537.36",
      "Mozilla/5.0 (Linux; Android 6.0.1; SM-G935S Build/MMB29K; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/55.0.2883.91 Mobile Safari/537.36",
      "Mozilla/5.0 (Linux; Android 6.0.1; SM-G920V Build/MMB29K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.98 Mobile Safari/537.36",
      "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 6P Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.83 Mobile Safari/537.36",
      "Mozilla/5.0 (Linux; Android 6.0.1; E6653 Build/32.2.A.0.253) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.98 Mobile Safari/537.36"
    ]
  end

  defp ts do
    DateTime.to_unix(DateTime.utc_now())
  end
end
