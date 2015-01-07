require "prawn"
require "rexml/document"
require "net/http"

def border_circles(pdf, palette_id)
    x_num_circles = 8
    y_num_circles = 9

    width = pdf.bounds.right - pdf.bounds.left
    # Corners occur in the x circles, not the y
    x_spacing = width / (x_num_circles - 1)

    height = pdf.bounds.top - pdf.bounds.bottom
    y_spacing = height / (y_num_circles + 1)

    # Take the average of the two spacings to find the radius
    radius = 0.4 * (x_spacing + y_spacing) / 2

    colours = get_colour_lovers_palette(palette_id)

    x_num_circles.times do |i|
        x = pdf.bounds.left + i * x_spacing

        pdf.fill_color colours.sample #randomly select a new colour
        pdf.fill_circle [x, pdf.bounds.top], radius

        pdf.fill_color colours.sample
        pdf.fill_circle [x, pdf.bounds.bottom], radius
    end

    y_num_circles.times do |i|
        y = pdf.bounds.bottom + (i + 1) * y_spacing

        pdf.fill_color colours.sample
        pdf.fill_circle [pdf.bounds.left, y], radius

        pdf.fill_color colours.sample
        pdf.fill_circle [pdf.bounds.right, y], radius
    end
end

def get_colour_lovers_palette(palette_id)
    url = "http://www.colourlovers.com/api/palette/#{palette_id}"
    xml_data = Net::HTTP.get_response(URI.parse(url)).body
    doc = REXML::Document.new(xml_data)
    colours = []
    doc.elements.each("palettes/palette/colors/hex") do |element|
        colours.push(element.text) # a 6-digit hex string
    end
    return colours
end

