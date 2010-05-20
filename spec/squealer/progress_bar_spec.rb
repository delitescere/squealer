require 'spec_helper'

describe Squealer::ProgressBar do
  let(:total) { 200 }
  let(:progress_bar) do
    testable_progress_bar = Class.new(Squealer::ProgressBar) do
      attr_reader :emitter
      public :total, :ticks, :percentage, :progress_markers, :emit,
             :duration, :start_time, :end_time, :progress_bar_width

      def console
        @console ||= StringIO.new
      end

      alias real_start_emitter start_emitter 
      def start_emitter; end
      public :real_start_emitter

    end
    testable_progress_bar.new(total).start
  end
  let(:console) { progress_bar.console }
  let(:progress_bar_width) { progress_bar.progress_bar_width }

  before { progress_bar.start }
  after { progress_bar.finish }

  it "allows only one progress bar at a time" do
    Squealer::ProgressBar.new(0).should be_nil
  end

  it "records the starting time" do
    progress_bar.start_time.should be_an_instance_of(Time)
  end

  it "records the starting time" do
    progress_bar.start_time.should be_an_instance_of(Time)
  end

  context "threaded" do
    before { progress_bar.stub(:emitter).and_return(progress_bar.real_start_emitter) }
    after { progress_bar.emitter.kill }

    it "has an emitter" do
      progress_bar.tick
      progress_bar.emitter.should_not be_nil
    end

    it "emits at least once" do
      progress_bar.tick
      progress_bar.emitter.wakeup
      sleep 0.1
      console.string.split("\r").length.should > 0
    end
  end

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

    it "records the ending time when finished" do
      progress_bar.finish
      progress_bar.end_time.should be_an_instance_of(Time)
    end

    it "prints a progress bar to the console" do
      progress_bar.finish
      progress_bar.emit
      console.string.split("\n").first.should == "\r[#{'=' * progress_bar_width}] #{ticks}/#{total} (100%)"
    end
  end

  context "multiple emits" do
    let(:ticks) { total }
    subject { console.string }
    before do
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
        progress_bar.finish
        progress_bar.emit

        subject.split("\r").size.should == 3
        subject[-1, 1].should == "\n"
      end

      it "emitted final timings" do
        ticks.times { progress_bar.tick }
        progress_bar.finish
        progress_bar.emit

        subject.should include("Start: #{progress_bar.start_time}\n")
        subject.should include("End: #{progress_bar.end_time}\n")
        subject.should include("Duration: #{progress_bar.duration}\n")
      end
    end
  end
end
