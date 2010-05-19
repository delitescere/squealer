require 'spec_helper'

describe Squealer::ProgressBar do
  let(:total) { 200 }
  let(:progress_bar) do
    testable_progress_bar = Class.new(Squealer::ProgressBar) do
      attr_accessor :start_time, :end_time, :progress_bar_width
      public :total, :ticks, :percentage, :progress_markers
    end
    testable_progress_bar.new(total)
  end
  let(:progress_bar_width) { progress_bar.progress_bar_width }

  context "no items completed" do
    it "emits the total number provided" do
      progress_bar.total.should == total
    end

    it "emits the number of ticks" do
      progress_bar.ticks.should == 0
    end

    it "displays an empty bar" do
      progress_bar.progress_markers.size.should == 0
    end

    it "prints a progress bar to the console" do
      console = StringIO.new
      progress_bar.stub(:console).and_return(console)
      progress_bar.emit
      console.string.should == "\r[#{' ' * progress_bar_width}]   #{0}/#{total} (0%)"
    end
  end

  context "one item completed" do
    before { progress_bar.tick }
    it "emits the number of ticks" do
      progress_bar.ticks.should == 1
    end

    it "emits the number of ticks as a percentage of the total number (rounded down)" do
      progress_bar.percentage.should == 0
    end

    it "records the starting time on the first tick" do
      progress_bar.start_time.should be_an_instance_of(Time)
    end
  end

  context "1/nth complete (where n is the width of the progress bar)" do
    let(:ticks) { (total / progress_bar_width) }
    before { ticks.times { progress_bar.tick } }
    it "emits the number of ticks" do
      progress_bar.ticks.should == ticks
    end

    it "emits the number of ticks as a percentage of the total number (rounded down)" do
      progress_bar.percentage.should == (ticks.to_f * 100 / total).floor
    end

    it "displays the first progress marker" do
      progress_bar.progress_markers.size.should == 1
    end

    it "prints a progress bar to the console" do
      console = StringIO.new
      progress_bar.stub(:console).and_return(console)
      progress_bar.emit
      percentag = (ticks.to_f * 100 / total).floor
      console.string.should == "\r[=#{' ' * (progress_bar_width - 1)}]   #{ticks}/#{total} (#{percentag}%)"
    end
  end

  context "all but one item completed" do
    let(:ticks) { total - 1 }
    before { ticks.times { progress_bar.tick } }

    it "emits the number of ticks" do
      progress_bar.ticks.should == ticks
    end

    it "emits the number of ticks as a percentage of the total number (rounded down)" do
      progress_bar.percentage.should == 99
    end

    it "has not yet displayed the final progress marker" do
      progress_bar.progress_markers.size.should == (progress_bar_width - 1)
    end
  end

  context "all items completed" do
    let(:ticks) { total }
    before { ticks.times { progress_bar.tick } }

    it "emits the number of ticks" do
      progress_bar.ticks.should == ticks
    end

    it "emits 100%" do
      progress_bar.percentage.should == 100
    end

    it "fills the progress bar with progress markers" do
      progress_bar.progress_markers.size.should == progress_bar_width
    end

    it "records the ending time on the last tick" do
      progress_bar.end_time.should be_an_instance_of(Time)
    end

    it "prints a progress bar to the console" do
      console = StringIO.new
      progress_bar.stub(:console).and_return(console)
      progress_bar.emit
      console.string.should == "\r[#{'=' * progress_bar_width}] #{ticks}/#{total} (100%)\n"
    end
  end

  context "multiple emits" do
    let(:console) { StringIO.new }
    let(:ticks) { total }
    subject { console.string }
    before do
      progress_bar.stub(:console).and_return(console)
      progress_bar.emit
    end

    context "not done" do
      it "emitted two lines with no final newline" do
        progress_bar.emit

        subject.split("\r").size.should == 3
        subject[-1, 1].should_not == "\n"
      end
    end

    context "done" do
      it "emitted two lines with a final newline" do
        ticks.times { progress_bar.tick }
        progress_bar.emit

        subject.split("\r").size.should == 3
        subject[-1, 1].should == "\n"
      end
    end
  end
end
