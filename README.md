# Kerala Election Results 2020

### Installation
To run app, you need elixir/erlang installed.
So do that maybe from: https://github.com/asdf-vm/asdf-elixir

Then install app dependecies:
```bash
$ mix deps.get
$ iex -S mix
```

### Running full scrape which saves district wise data to `data/` folder
```
iex> Ke.start()
:ok
```

### Get data for a district
```
iex> Ke.get_districts()
["D01001", "D02001", "D03001", "D04001", "D05001", "D06001", "D07001", "D08001",
 "D09001", "D10001", "D11001", "D12001", "D13001", "D14001"]

iex> Ke.get_full_district("D01001")
19:58:27.058 [debug] Starting to parse district D01001

19:58:27.065 [debug] Fetching gram_panchayats for dist_code: D01001

19:58:29.488 [debug] Fetching block_panchayats for dist_code: D01001

19:58:30.727 [debug] Fetching district_panchayats for dist_code: D01001

19:58:31.816 [debug] Fetching urban bodies for dist_code: D01001

19:58:31.900 [debug] Fetching ward data for: G01014 - AMBOORI

19:58:32.991 [debug] Fetching ward data for: G01043 - ANADU

19:58:34.085 [debug] Fetching ward data for: G01061 - ANCHUTHENGU

19:58:35.200 [debug] Fetching ward data for: G01027 - ANDOORKONAM

19:58:36.300 [info]  --------------------------------------------------

19:58:36.300 [debug] Fetching block data for: B01003 - ATHIYANOOR

19:58:37.386 [debug] Fetching block data for: B01010 - CHIRAYINKEEZHU
.
.
.
.
:ok
```

This function by default saves final data into `data/D01001_data.json`
