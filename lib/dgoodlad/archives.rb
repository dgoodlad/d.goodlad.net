module Dgoodlad
  module Archives
    def create_archive_items
      archive_template = @items.find { |i| i.identifier == '/archive_template/' }
      article_years.each do |year|
        lastmod = articles_by_year[year].map { |a| a.mtime }.max
        freq = (year == Time.now.year ? 'DAILY' : 'YEARLY')
        priority = 0.5
        @items << Nanoc3::Item.new(
          archive_template.raw_content,
          { :extension => 'erb', :year => year, :updatefreq => freq, :priority => priority },
          "/archives/#{year}",
          { :mtime => lastmod }
        )
      end
    end

    def articles_by_year
      grouped = articles.group_by { |a| Time.parse(a[:created_at]).year }
      if block_given?
        grouped.keys.sort.reverse.each do |year|
          yield [year, grouped[year]]
        end
      end
      grouped
    end

    def article_years
      articles.map { |a| Time.parse(a[:created_at]).year }.uniq.sort
    end

    def archive_pages
      @items.select { |i| i.identifier =~ %r(^/archives/\d{4}) }.sort_by { |i| i[:year] }
    end
  end
end
