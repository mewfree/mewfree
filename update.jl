using Dates
using UnicodePlots
using HTTP
using JSON

function query_data(coin, from, to)
    url = "https://api.coingecko.com/api/v3/coins/$(coin)/market_chart/range?vs_currency=usd&from=$(from)&to=$(to)"
    r = HTTP.request("GET", url)
    r.body |> String |> JSON.parse
end

function format_data(json)
    prices = json["prices"]
    Dict("x" => map(p->p[1], prices), "y" => map(p->p[2], prices))
end

function generate_graph(data)
    p = lineplot(
        data["x"],
        data["y"],
        title = "BTC price last 24 hours",
        xlabel = "UNIX timestamp",
        ylabel = "\$ USD",
        canvas = DotCanvas,
        border = :ascii)
    fn = "graph.txt"

    savefig(p, fn)
    read(fn, String)
end

function format_md(chart)
    header = """
# 👋

```
"""
    footer = """

```
📈 Data provided by CoinGecko

🧑‍💻 I'm Damien

✍️ I blog at [damiengonot.com](https://www.damiengonot.com)

🎨 Code is art, therefore you're an artist
"""

header * chart * footer
end

function write_md(md)
    f = open("README.md", "w")
    write(f, md)
    close(f)
end

function git_commit_push()
    run(`rm graph.txt`)
    run(`git add README.md`)
    run(`git commit -m $(Dates.format(Dates.now(), "yyyy-mm-dd HH:MM"))`)
    run(`git push origin main`)
end

ts = round(Int, time())
query_data("bitcoin", ts-(60*60*24), ts) |> format_data |> generate_graph |> format_md |> write_md
git_commit_push()
