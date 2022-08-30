using Dates
using UnicodePlots
using HTTP
using JSON
using Diana

function query_data(coin, from, to)
    url = "https://api.coingecko.com/api/v3/coins/$(coin)/market_chart/range?vs_currency=usd&from=$(from)&to=$(to)"
    r = HTTP.request("GET", url)
    r.body |> String |> JSON.parse
end

function format_data(json)
    prices = json["prices"]
    Dict("x" => map(p -> p[1] / 1000, prices), "y" => map(p -> p[2], prices))
end

function generate_graph(data)
    p = lineplot(
        data["x"],
        data["y"],
        title="BTC price last 24 hours",
        xlabel="UNIX timestamp",
        ylabel="\$ USD",
        width=60,
        canvas=DotCanvas,
        border=:ascii)
    fn = "graph.txt"

    savefig(p, fn)
    read(fn, String)
end

function format_org(chart)
    header = """
* 👋

#+begin_example
"""
    footer = """

#+end_example
📈 Data provided by CoinGecko

🧑‍💻 I'm Damien

✍️ I blog at [[https://www.damiengonot.com][damiengonot.com]]
"""

    header * chart * footer
end

function write_org(org)
    f = open("readme.org", "w")
    write(f, org)
    close(f)
end

function git_commit_push()
    run(`rm graph.txt`)
    run(`git add readme.org`)
    run(`git commit -m $(Dates.format(Dates.now(), "yyyy-mm-dd HH:MM"))`)
    run(`git push origin main`)
end

ts = round(Int, time())
data = query_data("bitcoin", ts - (60 * 60 * 24), ts)
data |> format_data |> generate_graph |> format_org |> write_org
git_commit_push()

gh_token = ENV["GH_TOKEN"]
gh_client = GraphQLClient("https://api.github.com/graphql", auth="bearer $gh_token")
query = """
mutation(\$emoji: String!, \$message: String!, \$limited: Boolean!) {
    changeUserStatus(input: {emoji: \$emoji, message: \$message, limitedAvailability: \$limited}) {
        status {
            message
            emoji
        }
    }
}
"""

function btc_going_up(data)
    x = first(data["prices"])[2]
    y = last(data["prices"])[2]

    if y > x
        true
    else
        false
    end
end

if btc_going_up(data)
    gh_client.Query(query, vars=Dict("emoji" => "📈", "message" => "BTC is going up!", "limited" => false))
else
    gh_client.Query(query, vars=Dict("emoji" => "📉", "message" => "BTC is going down...", "limited" => false))
end
