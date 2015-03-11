module Workers
  class SyncNetIDs
    include Sidekiq::Worker
    include Sidetiq::Schedulable

    recurrence do
      hourly.hour_of_day(*(8..20).to_a).day(:monday, :tuesday, :wednesday, :thursday, :friday)
    end

    def perform
      ids = ids_to_sync
      Log.info "Found #{ids.length} NetIDs not in Trogdir"

      ids.each do |id|
        SyncNetID.perform_async(id)
      end
    end

    private

    def trogdir_people_without_netids
      with_netids = Person.where('ids.type' => :netid)
      Person.where(:_id.nin => with_netids.pluck(:_id))
    end

    def ids_to_sync
      ids = biola_ids_for(trogdir_people_without_netids)
      mysql.query("SELECT idnumber FROM netids WHERE idnumber IN(#{ids.join(',')});").each(as: :array).flatten
    end

    def mysql
      Mysql2::Client.new(Settings.ws.mysql.to_hash)
    end

    def biola_ids_for(trogdir_people)
      trogdir_people.pluck(:ids).compact.map{|ids| ids.find{|id| id['type'] == :biola_id }.try(:[], 'identifier')}.compact.map(&:to_i)
    end
  end
end
