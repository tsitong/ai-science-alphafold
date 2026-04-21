set linesize 255
import delimited "data.csv", clear

sort author_id

psmatch2 treated (pub_count from_bio_med mean_team_size first_entry_year), neighbor(1)
pstest, both
drop pub_count

reshape long pub_count_, i(author_id) j(year)
gen post = year >= 2020
gen did = treated * post * is_top_aff
drop if year < 2017

label variable did "AlphaFold"

drop if _weight <= 0 | missing(_weight)
gen log_pub_count = log1p(pub_count)

/* Testing the Parallel Trends Assumption */

gen n_year = year - 2020

gen year_af = n_year * treated
gen af_top = treated * is_top_aff
gen top_year = is_top_aff * n_year
gen af_year_top = treated * n_year * is_top_aff

eststo clear

reg log_pub_count year_af treated n_year if year < 2020, robust cluster(author_id)

reg log_pub_count af_year_top year_af af_top top_year treated n_year is_top_aff if year < 2020, robust cluster(author_id)

/* Run DiD */

eststo clear

reghdfe log_pub_count treated##post, absorb(author_id year) vce(cluster author_id)

reghdfe log_pub_count treated##post, absorb(author_id year##fieldid) vce(cluster author_id)

reghdfe log_pub_count treated##post if is_top_aff == 0, absorb(author_id year) vce(cluster author_id)

reghdfe log_pub_count treated##post if is_top_aff == 1, absorb(author_id year) vce(cluster author_id)

reghdfe log_pub_count treated##post if is_top_aff == 0, absorb(author_id year##fieldid) vce(cluster author_id)

reghdfe log_pub_count treated##post if is_top_aff == 1, absorb(author_id year##fieldid) vce(cluster author_id)

reghdfe log_pub_count treated##post##is_top_aff, absorb(author_id year##fieldid) vce(cluster author_id)
