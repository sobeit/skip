# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ranking, '.total' do
  before  do
    @datetime = Time.local(2008, 7, 15)
    create_ranking(:url => 'http://user.openskip.org/foo', :contents_type => 'entry_access', :extracted_on => @datetime.yesterday, :amount => 1)
    create_ranking(:url => 'http://user.openskip.org/foo', :contents_type => 'entry_access', :extracted_on => @datetime, :amount => 2)
    create_ranking(:url => 'http://user.openskip.org/foo', :contents_type => 'entry_access', :extracted_on => @datetime.tomorrow, :amount => 3)
    create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime.yesterday, :amount => 4)
    create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 5)
    create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime.tomorrow, :amount => 6)
    create_ranking(:url => 'http://user.openskip.org/bar', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 7)
  end

  it 'url及び指定したcontents_typeでグルーピングされたランキングが取得できること' do
    Ranking.total(:entry_access).should have(1).items
    Ranking.total(:comment_access).should have(2).items
  end
  # it 'url及び指定したcontents_type毎にextracted_onが最新のデータが抽出されていること'
end

describe Ranking, '.monthly' do
  describe '複数種類のcontents_typeのデータがある場合' do
    before do
      @datetime = Time.local(2008, 7, 15)
      create_ranking(:url => 'http://user.openskip.org/foo', :contents_type => 'entry_access', :extracted_on => @datetime, :amount => 2)
      create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 5)
    end
    it '指定したcontents_typeのデータのみ抽出されること' do
      Ranking.monthly(:entry_access, @datetime.year, @datetime.month).should have(1).items
      Ranking.monthly(:comment_access, @datetime.year, @datetime.month).should have(1).items
    end
    it '存在しないcontents_typeのデータは抽出されないこと' do
      Ranking.monthly(:hoge, @datetime.year, @datetime.month).should have(0).items
    end
  end

  describe '複数のurlのデータがある場合' do
    before do
      @datetime = Time.local(2008, 7, 15)
      create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 5)
      create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime.yesterday, :amount => 4)
      create_ranking(:url => 'http://user.openskip.org/bar', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 7)
    end
    it 'urlでグルーピングされること' do
      Ranking.monthly(:comment_access, @datetime.year, @datetime.month).should have(2).items
    end
  end

  describe '単一のcontents_type及び、単一のurlのデータの場合' do
    describe '前月以前にデータがある場合' do
      before do
        @datetime = Time.local(2008, 7, 15)
        create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime.ago(2.month), :amount => 4)
        create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime.yesterday, :amount => 4)
        create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 5)
        create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime.tomorrow, :amount => 6)
      end
      it '指定月でextracted_onが最大となるレコードのamount - 前月最終日以前でextracted_onが最大となるレコードのamountとなっていること' do
        Ranking.monthly(:comment_access, @datetime.year, @datetime.month).first.amount.should == 2 
      end
    end

    describe '前月以前にデータがない場合' do
      before do
        @datetime = Time.local(2008, 7, 15)
        create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime.yesterday, :amount => 4)
        create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 5)
        create_ranking(:url => 'http://user.openskip.org/hoge', :contents_type => 'comment_access', :extracted_on => @datetime.tomorrow, :amount => 6)
      end
      it '指定月でextracted_onが最大となるレコードのamountとなっていること' do
        Ranking.monthly(:comment_access, @datetime.year, @datetime.month).first.amount.should == 6
      end
    end
  end

  describe '単一のcontents_typeで、10種類を超えるurlのデータがある場合' do
    before do
      @datetime = Time.local(2008, 7, 15)
      create_ranking(:url => 'http://user.openskip.org/1', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 1)
      create_ranking(:url => 'http://user.openskip.org/2', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 2)
      create_ranking(:url => 'http://user.openskip.org/3', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 3)
      create_ranking(:url => 'http://user.openskip.org/4', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 4)
      create_ranking(:url => 'http://user.openskip.org/5', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 5)
      create_ranking(:url => 'http://user.openskip.org/6', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 6)
      create_ranking(:url => 'http://user.openskip.org/7', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 7)
      create_ranking(:url => 'http://user.openskip.org/8', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 8)
      create_ranking(:url => 'http://user.openskip.org/9', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 9)
      create_ranking(:url => 'http://user.openskip.org/10', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 10)
      create_ranking(:url => 'http://user.openskip.org/11', :contents_type => 'comment_access', :extracted_on => @datetime, :amount => 11)
    end
    it '10件のデータが抽出されること' do
      Ranking.monthly(:comment_access, @datetime.year, @datetime.month).should have(10).items
    end
  end
end

describe Ranking, '.extracted_dates' do
  describe 'extracted_onが同月のレコードが2件の場合' do
    before do
      create_ranking(:extracted_on => Time.local(2008, 11, 1))
      create_ranking(:extracted_on => Time.local(2008, 11, 2))
    end
    it { Ranking.extracted_dates.should == ['2008-11'] }
  end
  describe 'extracted_onが異なる月のレコードが2件の場合' do
    before do
      create_ranking(:extracted_on => Time.local(2008, 11, 1))
      create_ranking(:extracted_on => Time.local(2008, 12, 1))
    end
    it { Ranking.extracted_dates.should == ['2008-12', '2008-11'] }
  end
  describe 'extracted_onが同月のレコードが2件、異なる月のレコードが1件の場合' do
    before do
      create_ranking(:extracted_on => Time.local(2008, 11, 1))
      create_ranking(:extracted_on => Time.local(2008, 11, 2))
      create_ranking(:extracted_on => Time.local(2008, 12, 1))
    end
    it { Ranking.extracted_dates.should == ['2008-12', '2008-11'] }
  end
end

def create_ranking(options = {})
  ranking = Ranking.new({
    :url => 'http://user.openskip.org/',
    :title => 'SUG',
    :extracted_on => Date.today,
    :amount => 1,
    :contents_type => 'entry_access'}.merge(options))
  ranking.save
  ranking
end
