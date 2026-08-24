#include <hb.h>
#include <hb-ot.h>
#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <iomanip>

struct GlyphTrace {
    uint32_t codepoint;
    uint32_t cluster;
    uint32_t mask;
};

struct StageTrace {
    std::string stage;
    std::vector<GlyphTrace> glyphs;
};

struct TraceResult {
    std::string text;
    std::vector<StageTrace> stages;
};

static hb_bool_t message_handler(hb_buffer_t *buffer, hb_font_t *font, const char *message, void *user_data) {
    auto *result = static_cast<TraceResult*>(user_data);
    unsigned int count = 0;
    hb_glyph_info_t *infos = hb_buffer_get_glyph_infos(buffer, &count);
    
    StageTrace st;
    st.stage = message;
    for (unsigned int i = 0; i < count; i++) {
        GlyphTrace gt;
        gt.codepoint = infos[i].codepoint;
        gt.cluster = infos[i].cluster;
        gt.mask = infos[i].mask;
        st.glyphs.push_back(gt);
    }
    result->stages.push_back(st);
    return true;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <string_to_trace>" << std::endl;
        return 1;
    }

    std::string input = argv[1];

    hb_blob_t *blob = hb_blob_create_from_file("assets/fonts/Battambang-Regular.ttf");
    if (!blob) {
        std::cerr << "Failed to load font file." << std::endl;
        return 1;
    }
    hb_face_t *face = hb_face_create(blob, 0);
    hb_font_t *font = hb_font_create(face);

    hb_buffer_t *buf = hb_buffer_create();
    hb_buffer_add_utf8(buf, input.c_str(), -1, 0, -1);
    hb_buffer_set_script(buf, HB_SCRIPT_KHMER);
    hb_buffer_set_direction(buf, HB_DIRECTION_LTR);
    hb_buffer_guess_segment_properties(buf);

    TraceResult result;
    result.text = input;

    hb_buffer_set_message_func(buf, message_handler, &result, nullptr);

    hb_shape(font, buf, nullptr, 0);

    // Output JSON
    std::cout << "{\n";
    std::cout << "  \"text\": \"" << input << "\",\n";
    std::cout << "  \"stages\": [\n";
    for (size_t s = 0; s < result.stages.size(); s++) {
        const auto &st = result.stages[s];
        std::cout << "    {\n";
        std::cout << "      \"stage\": \"" << st.stage << "\",\n";
        std::cout << "      \"glyphs\": [\n";
        for (size_t g = 0; g < st.glyphs.size(); g++) {
            const auto &gt = st.glyphs[g];
            std::cout << "        {\"codepoint\": " << gt.codepoint
                      << ", \"cluster\": " << gt.cluster
                      << ", \"mask\": " << gt.mask << "}"
                      << (g + 1 < st.glyphs.size() ? "," : "") << "\n";
        }
        std::cout << "      ]\n";
        std::cout << "    }" << (s + 1 < result.stages.size() ? "," : "") << "\n";
    }
    std::cout << "  ]\n";
    std::cout << "}\n";

    hb_buffer_destroy(buf);
    hb_font_destroy(font);
    hb_face_destroy(face);
    hb_blob_destroy(blob);

    return 0;
}
