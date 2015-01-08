require "prawn"
require "yaml"
require "rexml/document"
require "net/http"
require_relative "borders"

def main()
	cfg_file = begin
		File.open("config.yml")
	rescue
		print "ERROR: config.yml not found, exiting."
		exit
	end

	cfg = begin
		YAML::load(cfg_file)
	rescue ArgumentError => e
		puts "Could not parse YAML: #{e.message}"
		exit
	end

	puts "Config file succesfully read."

    cfg["cards"].values.each {|card_cfg| create_card(cfg, card_cfg)}
end

def gen_body_text(cfg, card_cfg)
    body_text = ""

    phrase_blocks = cfg["phrases"]
    # An arbitrary number of blocks are given by the user
    phrase_blocks.each do |block_name, phrases|
        puts "Choosing a phrase from #{block_name}."

        # The phrases can contain substrings of the form %GIFT%, which
        # reference the gift_received parameter in card_cfg.
        phrase = phrases.sample.gsub(/%GIFT%/, card_cfg["gift_received"])

        puts "Phrase chosen: '#{phrase}'"
        body_text += phrase + " "
    end

	return body_text
end

def create_card(cfg, card_cfg)
	pdf = Prawn::Document.new( :page_size => cfg["page_size"] )

    name             = cfg["name"]
    block_spacing    = cfg["block_spacing"]
	padding          = cfg["text_padding"]
    output_directory = cfg["output_directory"]
	pdf.font cfg["font"]
	pdf.font_size cfg["font_size"]

    recipient      = card_cfg["recipient"]
    gift_received  = card_cfg["gift_received"]
    include_kisses = card_cfg["include_kisses"]
    output_name    = card_cfg["output_name"]

    # Generating text
    greeting = "Dear #{recipient},"

    body = gen_body_text(cfg, card_cfg)

    ending = "Lots of love from #{name}"
    if include_kisses then ending += "\nxxx" end

    # Calculating text box size
    total_text_height =
        pdf.height_of(greeting) +
        pdf.height_of(body) +
        pdf.height_of(ending) +
        2 * block_spacing

    text_top_bound =
        (pdf.bounds.top - pdf.bounds.bottom) / 2 +
        0.5 * total_text_height 

    text_left_bound =
        pdf.bounds.left + padding

	text_box_width = pdf.bounds.right - pdf.bounds.left - 2 * padding
	text_box_height = pdf.bounds.top - pdf.bounds.bottom - 2 * padding
    
    puts "total_text_height: #{total_text_height}"
    puts "text_top_bound: #{text_top_bound}"

	# Create the bounding box where text will go 
	pdf.bounding_box(
		[text_left_bound,
         text_top_bound],
		:width => text_box_width,
		:height => text_box_height) do

		pdf.text greeting, :align => :left
        pdf.move_down block_spacing
		pdf.text body, :align => :center
        pdf.move_down block_spacing
        pdf.text ending, :align => :center
	end

	pdf.transparent(0.5) do
		pdf.stroke_bounds
	end

    # imported from borders.rb
    draw_border(pdf, cfg)

    puts "Saved pdf file as #{output_name}."

    if File.directory?(output_directory) == false
        puts "Output directory #{output_directory} does not exist so creating it..."
        Dir.mkdir(output_directory)
    end

	pdf.render_file(output_directory + '/' + output_name)
end

def test_fonts()
    Prawn::Document.generate("font_test.pdf") do
        font_size 20
        for font_name in Prawn::Font::AFM::BUILT_INS
            font font_name
            text "#{font_name}: The quick brown dog jumped over the lazy fox."
            move_down 10
        end
    end
end

main()
