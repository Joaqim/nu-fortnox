# nu-fortnox

WIP, currently primarily focused on supporting Fortnox API for resource: 'invoices'

```nushell
fortnox invoices --for-quarter 1 --for-year 2024 --page 1.. 
    | to csv 
    | save Invoices_2024-Q1.csv
```


Or fetch a list of invoices by length 1 ( where '--limit' is equivalent to 'per page' ):

```nushell
fortnox invoices -l 1 
```

## Installation

```nushell
git submodule update --init
use nupm
nump install --force --path .
```

## Usage

```nushell
use .
overlay use nu-fortnox
fortnox invoices -h # To show all available flags
```
or
```nushell
use . *
fortnox invoices -h # To show all available flags
```



### Configuration

nu-fortnox expects mongodb database to contain a collection 'credentials' with the following pre-existing document for OAuth tokens from Fortnox:

```typescript
type {
    expiresAt?: ISODate(),
    accessToken?: string,

    provider: "fortnox", // Can be changed with $env._FORTNOX_DB_CREDENTIALS_QUERY
    clientIdentity: string,
    clientSecret: string,
    refreshToken: string, 
}
```

It will try to create/update fields for 'expiresAt', 'accessToken' and 'refreshToken' after using refresh token with Fortnox API.


### Create .env.nu

```nushell
export-env {
    $env.DB_CONNECTION_STRING = "mongodb://<login>:<password>@localhost:27017/my-database"
    $env._FORTNOX_USE_CACHE = true
    $env._FORTNOX_DB_CREDENTIALS_QUERY = '{"provider": "fortnox"}'
}
```

### Flags
```typescript
Flags:
  -i, --invoice-number <Int> - Fetch specific invoice, returns list<record>
  -f, --filter-by-your-order-number <String> - Filter by 'YourOrderNumber'
  -c, --customer-name <String> - Filter by 'CustomerName'
  -m, --last-modified <DateTime> - Filter by last modification date for Fortnox documents

  -s, --from-date <String> - Fortnox 'fromdate' param, expects 'YYYY-M-D'
  -e, --to-date <String> - Fortnox 'fromdate' param, expects 'YYYY-M-D'

  -Y, --for-year <Int> - Specify from/to date range by year, expects integer above 1970
  -Q, --for-quarter <Int> - Specify from/to date range by quarter, expects integer [1-4]
  -M, --for-month <Int> - Specify from/to date range by month, expects integer [1-12]
  -D, --for-day <Int> - Specify from/to date range by day, expects integer [1-32]

  --full-date <String> - Specify specific date WIP

  --filter-by-unbooked - Filter by 'unbooked' status in Fortnox
  --filter-by-cancelled - Filter by 'cancelled' status in Fortnox
  --filter-by-fullypaid - Filter by 'fullypaid' status in Fortnox
  --filter-by-unpaid - Filter by 'unpaid' status in Fortnox
  --filter-by-unpaidoverdue - Filter by 'unpaidoverdue' status in Fortnox

  -F, --filter-override <String> - Use specified filter param in Fortnox request

  --no-cache - Don't use cache for request. NOTE: received resource doesn't overwrite existing cache
  -b, --brief - Remove empty values
  -O, --obfuscate - Remove Customer's info, but not customer's country

  -l, --limit <Int> - Limit how many resources to fetch, expects integer [1-100] (default: 100)
  -p, --page <Range> - If range is higher than 1..1, limit must be set to 100 (default: 1..1)
  -s, --sort-by <String> - Set 'sortby' param for Fortnox request (default: 'invoicedate')
  -s, --sort-order <String> - Set 'sortorder' param for Fortnox Request, expects 'ascending' or 'descending' (default: 'descending')
  -h, --help - Display the help message for this command
```

