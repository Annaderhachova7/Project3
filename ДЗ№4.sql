 --основне завдання
with facebookdata as
(
select 
	fabd.ad_date,
	fa.adset_name,
	fc.campaign_name,
	fabd.spend,
	fabd.impressions,
	fabd.reach,
	fabd.clicks,
	fabd.leads,
	fabd.value
from 
	facebook_ads_basic_daily fabd
left join 
	facebook_adset fa on fabd.adset_id = fa.adset_id
left join 
	facebook_campaign fc on fabd.campaign_id = fc.campaign_id
),
googledata as 
(
select 
	gabd.ad_date,
	'Google Ads' as media_source,
	gabd.campaign_name,
	gabd.adset_name,
	gabd.spend,
	gabd.impressions,
	gabd.reach,
	gabd.clicks,
	gabd.leads,
	gabd.value
from google_ads_basic_daily gabd 
)
select 
	ad_date,
	media_source,
	campaign_name,
	adset_name,
	sum (spend) as total_spend,
	sum (impressions) as total_imp,
	sum (clicks) as total_clicks,
	sum (value) as total_value,
	(sum (value::numeric)/sum (spend))-1 as romi
from 
(
select 
	ad_date,
	'Facebook Ads' as media_source,
	campaign_name,
	adset_name,
	spend,
	impressions,
	clicks,
	value
from 
	facebookdata
union all
select 
	ad_date,
	media_source,
	campaign_name,
	adset_name,
	spend,
	impressions,
	clicks,
	value
from googledata
)
as fgdata
where spend>0
group by 
	ad_date,
	media_source,
	adset_name,
	campaign_name
order by 
	ad_date,
	media_source,
	campaign_name,
	adset_name
	;

--додаткове завдання
with facebookdata as
(
	select 
		fabd.ad_date,
		fa.adset_name,
		fc.campaign_name,
		fabd.spend,
		fabd.impressions,
		fabd.reach,
		fabd.clicks,
		fabd.leads,
		fabd.value
	from 
		facebook_ads_basic_daily fabd
	left join 
		facebook_adset fa on fabd.adset_id = fa.adset_id
	left join 
		facebook_campaign fc on fabd.campaign_id = fc.campaign_id
),
googledata as 
(
	select 
		gabd.ad_date,
		'Google Ads' as media_source,
		gabd.campaign_name,
		gabd.adset_name,
		gabd.spend,
		gabd.impressions,
		gabd.reach,
		gabd.clicks,
		gabd.leads,
		gabd.value
	from google_ads_basic_daily gabd 
),
fgdata as
(
	select 
		facebookdata.ad_date,
		'Facebook Ads' as media_source,
		facebookdata.campaign_name,
		facebookdata.adset_name,
		facebookdata.spend,
		facebookdata.impressions,
		facebookdata.clicks,
		facebookdata.value
	from 
		facebookdata
	union all
	select 
		googledata.ad_date,
		googledata.media_source,
		googledata.campaign_name,
		googledata.adset_name,
		googledata.spend,
		googledata.impressions,
		googledata.clicks,
		googledata.value
	from googledata
),
agcampaign as 
(
	select
		campaign_name,
		sum (spend)as total_spend,
		sum (value) as total_value,
		(sum (value::numeric)/sum (spend))-1 as romi
	from fgdata
	where spend>0
	group by campaign_name
	having sum (spend)>500000
	order by romi desc 
	limit 1
)
select 
	adset_name,
	sum(spend) as total_spend,
	sum (value) as total_value,
	(sum (value::numeric)/sum(spend))-1 as romi
from fgdata 
where campaign_name=(select campaign_name from agcampaign)
group by adset_name
order by romi desc
limit 1;


select *
from facebook_ads_basic_daily fabd;


with all_ads_data as (
select
	fabd.ad_date,
	fc.campaign_name,
	fa.adset_name,
	fabd.spend,
	fabd.impressions,
	fabd.reach,
	fabd.clicks,
	fabd.leads,
	fabd.value
from
	facebook_ads_basic_daily fabd
left join facebook_adset fa on
	fa.adset_id = fabd.adset_id
left join facebook_campaign fc on
	fc.campaign_id = fabd.campaign_id
union all
select
	ad_date,
	campaign_name,
	adset_name,
	spend,
	impressions,
	reach,
	clicks,
	leads,
	value
from
	google_ads_basic_daily gabd
),
top_campaign as (
select
	ad_date,
		campaign_name, 
		sum(spend) as total_spend, 
		sum(value)::numeric / sum(spend) as romi
from
	all_ads_data aad
where
	spend > 0
group by
	campaign_name,
	ad_date
order by
	ad_date desc
)
select 
	aad.ad_date,
	aad.adset_name,
	sum(spend) as total_spend, 
	sum(value) as total_value, 
	sum(value)::numeric / sum(spend) as romi
from
	all_ads_data aad
join top_campaign tc on
	tc.campaign_name = aad.campaign_name
where
	spend > 0
group by
	adset_name,
	aad.ad_date
order by
	aad.ad_date desc;

