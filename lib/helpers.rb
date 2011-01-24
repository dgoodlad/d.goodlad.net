include Nanoc3::Helpers::XMLSitemap
include Nanoc3::Helpers::Blogging

def body_class
  case @item[:kind]
  when 'article' then 'article'
  when 'archives' then 'archives'
  else 'home'
  end
end

def articles_by_year
  grouped = articles.group_by { |a| Time.parse(a[:created_at]).year }
  if block_given?
    grouped.keys.sort.reverse.each do |year|
      yield [year, grouped[year]]
    end
  end
  p grouped
  grouped
end

def article_years
  articles.map { |a| Time.parse(a[:created_at]).year }.uniq.sort
end
