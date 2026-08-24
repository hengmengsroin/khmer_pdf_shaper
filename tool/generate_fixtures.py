#!/usr/bin/env python3
"""
Khmer Golden Oracle Generator for HarfBuzz Reference Tests
Generates structured JSON golden fixtures using uharfbuzz / HarfBuzz.
"""

import hashlib
import json
import os
import subprocess
import uharfbuzz as hb

def get_hb_version():
    try:
        out = subprocess.check_output(['hb-shape', '--version'], text=True).strip()
        return out
    except Exception:
        return f"uharfbuzz {hb.__version__}"

def get_sha256(filepath):
    with open(filepath, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()

def shape_string(font, text, script='Khmr', direction='ltr'):
    buf = hb.Buffer()
    buf.add_str(text)
    buf.script = script
    buf.direction = direction
    buf.guess_segment_properties()
    hb.shape(font, buf)
    
    glyphs = []
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        try:
            gname = font.glyph_to_string(info.codepoint)
        except Exception:
            gname = f"gid{info.codepoint}"
        glyphs.append({
            "glyph_id": info.codepoint,
            "glyph_name": gname,
            "cluster": info.cluster,
            "x_advance": float(pos.x_advance),
            "y_advance": float(pos.y_advance),
            "x_offset": float(pos.x_offset),
            "y_offset": float(pos.y_offset),
        })
    return glyphs

def build_corpus():
    items = []
    
    # 1. BASE: Consonants & Independent Vowels
    consonants = [
        ("base_ka", "ក", "Base consonant Ka (1st series velar)"),
        ("base_kha", "ខ", "Base consonant Kha (1st series velar aspirated)"),
        ("base_ko", "គ", "Base consonant Ko (2nd series velar)"),
        ("base_kho", "ឃ", "Base consonant Kho (2nd series velar aspirated)"),
        ("base_ngo", "ង", "Base consonant Ngo (2nd series velar nasal)"),
        ("base_ca", "ច", "Base consonant Ca (1st series palatal)"),
        ("base_nyo", "ញ", "Base consonant Nyo (2nd series palatal nasal)"),
        ("base_da", "ដ", "Base consonant Da (1st series retroflex)"),
        ("base_ta", "ត", "Base consonant Ta (1st series dental)"),
        ("base_to", "ទ", "Base consonant To (2nd series dental)"),
        ("base_na", "ណ", "Base consonant Na (1st series dental nasal)"),
        ("base_no", "ន", "Base consonant No (2nd series dental nasal)"),
        ("base_ba", "ប", "Base consonant Ba (1st series labial)"),
        ("base_pha", "ផ", "Base consonant Pha (1st series labial aspirated)"),
        ("base_po", "ព", "Base consonant Po (2nd series labial)"),
        ("base_mo", "ម", "Base consonant Mo (2nd series labial nasal)"),
        ("base_yo", "យ", "Base consonant Yo (2nd series semivowel)"),
        ("base_ro", "រ", "Base consonant Ro (2nd series liquid)"),
        ("base_lo", "ល", "Base consonant Lo (2nd series liquid)"),
        ("base_vo", "វ", "Base consonant Vo (2nd series semivowel)"),
        ("base_sa", "ស", "Base consonant Sa (1st series sibilant)"),
        ("base_ha", "ហ", "Base consonant Ha (1st series glottal)"),
        ("base_la", "ឡ", "Base consonant La (1st series liquid)"),
        ("base_qa", "អ", "Base consonant Qa (1st series glottal stop)"),
    ]
    for fid, text, reason in consonants:
        items.append({"id": fid, "text": text, "category": "BASE", "reason": reason})

    indep_vowels = [
        ("indep_qi", "ឥ", "Independent vowel Qi"),
        ("indep_qii", "ឦ", "Independent vowel Qii"),
        ("indep_qu", "ឧ", "Independent vowel Qu"),
        ("indep_quuk", "ឨ", "Independent vowel Quk"),
        ("indep_quu", "ឩ", "Independent vowel Quu"),
        ("indep_quuv", "ឪ", "Independent vowel Quuv"),
        ("indep_ry", "ឫ", "Independent vowel Ry (vocalic r)"),
        ("indep_ryy", "ឬ", "Independent vowel Ryy (long vocalic r)"),
        ("indep_ly", "ឭ", "Independent vowel Ly (vocalic l)"),
        ("indep_lyy", "ឮ", "Independent vowel Lyy (long vocalic l)"),
        ("indep_qe", "ឯ", "Independent vowel Qe"),
        ("indep_qai", "ឰ", "Independent vowel Qai"),
        ("indep_qoo1", "ឱ", "Independent vowel Qoo type 1"),
        ("indep_qoo2", "ឲ", "Independent vowel Qoo type 2"),
        ("indep_qau", "ឳ", "Independent vowel Qau"),
    ]
    for fid, text, reason in indep_vowels:
        items.append({"id": fid, "text": text, "category": "BASE", "reason": reason})

    # 2. VOWEL_PRE (Pre-base dependent vowels)
    vowel_pre = [
        ("vowel_pre_e_ka", "កេ", "Ka + Pre-base vowel E (U+17C1)"),
        ("vowel_pre_ae_ka", "កែ", "Ka + Pre-base vowel AE (U+17C2)"),
        ("vowel_pre_ai_ka", "កៃ", "Ka + Pre-base vowel AI (U+17C3)"),
        ("vowel_pre_e_ba", "បេ", "Ba + Pre-base vowel E"),
        ("vowel_pre_ae_ba", "បែ", "Ba + Pre-base vowel AE"),
        ("vowel_pre_ai_ba", "បៃ", "Ba + Pre-base vowel AI"),
        ("vowel_pre_e_sa", "សេ", "Sa + Pre-base vowel E"),
        ("vowel_pre_ae_ro", "រែ", "Ro + Pre-base vowel AE"),
    ]
    for fid, text, reason in vowel_pre:
        items.append({"id": fid, "text": text, "category": "VOWEL_PRE", "reason": reason})

    # 3. VOWEL_ABOVE (Above-base dependent vowels)
    vowel_above = [
        ("vowel_abv_i_ka", "កិ", "Ka + Vowel Sign I (U+17B7)"),
        ("vowel_abv_ii_ka", "កី", "Ka + Vowel Sign II (U+17B8)"),
        ("vowel_abv_y_ka", "កឹ", "Ka + Vowel Sign Y (U+17B9)"),
        ("vowel_abv_yy_ka", "កឺ", "Ka + Vowel Sign YY (U+17BA)"),
        ("vowel_abv_i_sa", "សិ", "Sa + Vowel Sign I"),
        ("vowel_abv_ii_ba", "បី", "Ba + Vowel Sign II"),
        ("vowel_abv_y_po", "ពឹ", "Po + Vowel Sign Y"),
        ("vowel_abv_yy_mo", "មឺ", "Mo + Vowel Sign YY"),
    ]
    for fid, text, reason in vowel_above:
        items.append({"id": fid, "text": text, "category": "VOWEL_ABOVE", "reason": reason})

    # 4. VOWEL_BELOW (Below-base dependent vowels)
    vowel_below = [
        ("vowel_blw_u_ka", "កុ", "Ka + Vowel Sign U (U+17BB)"),
        ("vowel_blw_uu_ka", "កូ", "Ka + Vowel Sign UU (U+17BC)"),
        ("vowel_blw_ua_ka", "កួ", "Ka + Vowel Sign UA (U+17BD)"),
        ("vowel_blw_u_ba", "បុ", "Ba + Vowel Sign U"),
        ("vowel_blw_uu_ba", "បូ", "Ba + Vowel Sign UU"),
        ("vowel_blw_ua_ba", "បួ", "Ba + Vowel Sign UA"),
        ("vowel_blw_u_nyo", "ញុ", "Nyo + Vowel Sign U (Nyo base trimming / context)"),
        ("vowel_blw_uu_nyo", "ញូ", "Nyo + Vowel Sign UU"),
    ]
    for fid, text, reason in vowel_below:
        items.append({"id": fid, "text": text, "category": "VOWEL_BELOW", "reason": reason})

    # 5. VOWEL_POST (Post-base dependent vowels)
    vowel_post = [
        ("vowel_pst_aa_ka", "កា", "Ka + Vowel Sign AA (U+17B6)"),
        ("vowel_pst_aa_ba", "បា", "Ba + Vowel Sign AA (Special ligature / wide space)"),
        ("vowel_pst_aa_sa", "សា", "Sa + Vowel Sign AA"),
        ("vowel_pst_aa_nyo", "ញា", "Nyo + Vowel Sign AA"),
        ("vowel_pst_aa_da", "ដា", "Da + Vowel Sign AA"),
    ]
    for fid, text, reason in vowel_post:
        items.append({"id": fid, "text": text, "category": "VOWEL_POST", "reason": reason})

    # 6. VOWEL_SPLIT (Decomposed split vowels)
    vowel_split = [
        ("vowel_split_oe_ka", "កើ", "Ka + Vowel OE (U+17BE -> E + OE_above)"),
        ("vowel_split_ya_ka", "កឿ", "Ka + Vowel YA (U+17BF -> E + YA_above)"),
        ("vowel_split_ie_ka", "កៀ", "Ka + Vowel IE (U+17C0 -> E + IE_above)"),
        ("vowel_split_oo_ka", "កោ", "Ka + Vowel OO (U+17C4 -> E + AA)"),
        ("vowel_split_au_ka", "កៅ", "Ka + Vowel AU (U+17C5 -> E + AU_post)"),
        ("vowel_split_oe_ba", "បើ", "Ba + Vowel OE"),
        ("vowel_split_oo_ba", "បោ", "Ba + Vowel OO"),
        ("vowel_split_au_ba", "បៅ", "Ba + Vowel AU"),
        ("vowel_split_oo_sa", "សោ", "Sa + Vowel OO"),
        ("vowel_split_ie_to", "ទៀ", "To + Vowel IE"),
    ]
    for fid, text, reason in vowel_split:
        items.append({"id": fid, "text": text, "category": "VOWEL_SPLIT", "reason": reason})

    # 7. COENG_BASIC (Basic subscripts)
    coeng_basic = [
        ("coeng_ka_ka", "ក្ក", "Ka + Coeng Ka"),
        ("coeng_ka_kha", "ក្ខ", "Ka + Coeng Kha"),
        ("coeng_ka_ko", "គ្ក", "Ko + Coeng Ka"),
        ("coeng_ka_ngo", "ក្ង", "Ka + Coeng Ngo"),
        ("coeng_ka_ca", "ក្ច", "Ka + Coeng Ca"),
        ("coeng_ka_nyo", "ក្ញ", "Ka + Coeng Nyo"),
        ("coeng_ka_da", "ក្ដ", "Ka + Coeng Da"),
        ("coeng_ka_ta", "ក្ដ", "Ka + Coeng Ta"),
        ("coeng_ka_na", "ក្ណ", "Ka + Coeng Na"),
        ("coeng_ka_ba", "ក្ដ", "Ka + Coeng Ba"),
        ("coeng_ka_po", "ក្ព", "Ka + Coeng Po"),
        ("coeng_ka_mo", "ក្ម", "Ka + Coeng Mo"),
        ("coeng_ka_yo", "ក្យ", "Ka + Coeng Yo"),
        ("coeng_ka_lo", "ក្ល", "Ka + Coeng Lo"),
        ("coeng_ka_vo", "ក្វ", "Ka + Coeng Vo"),
        ("coeng_ka_sa", "ក្ស", "Ka + Coeng Sa"),
        ("coeng_ka_ha", "ក្ហ", "Ka + Coeng Ha"),
        ("coeng_ka_la", "ក្ឡ", "Ka + Coeng La"),
        ("coeng_ka_qa", "ក្អ", "Ka + Coeng Qa"),
        ("coeng_nyo_nyo", "ញ្ញ", "Nyo + Coeng Nyo (Nyo base trimming)"),
        ("coeng_ba_ba", "ប្ប", "Ba + Coeng Ba"),
        ("coeng_sa_tha", "ស្ថ", "Sa + Coeng Tha"),
        ("coeng_sa_da", "ស្ត", "Sa + Coeng Da"),
    ]
    for fid, text, reason in coeng_basic:
        items.append({"id": fid, "text": text, "category": "COENG_BASIC", "reason": reason})

    # 8. COENG_RO (Pre-base subscript Ro)
    coeng_ro = [
        ("coeng_ro_ka", "ក្រ", "Ka + Coeng Ro (Pre-base reordering)"),
        ("coeng_ro_kha", "ខ្រ", "Kha + Coeng Ro"),
        ("coeng_ro_ko", "គ្រ", "Ko + Coeng Ro"),
        ("coeng_ro_to", "ទ្រ", "To + Coeng Ro"),
        ("coeng_ro_ba", "ច្រ", "Ca + Coeng Ro"),
        ("coeng_ro_pa", "ប្រ", "Ba + Coeng Ro"),
        ("coeng_ro_sa", "ស្រ", "Sa + Coeng Ro"),
        ("coeng_ro_ha", "ហ្រ", "Ha + Coeng Ro"),
        ("coeng_ro_ka_e", "គ្រេ", "Ko + Coeng Ro + Vowel E"),
        ("coeng_ro_ka_ae", "គ្រែ", "Ko + Coeng Ro + Vowel AE"),
        ("coeng_ro_ka_oo", "គ្រោ", "Ko + Coeng Ro + Vowel OO"),
        ("coeng_ro_ka_i", "គ្រិ", "Ko + Coeng Ro + Vowel I"),
        ("coeng_ro_ka_u", "គ្រុ", "Ko + Coeng Ro + Vowel U"),
    ]
    for fid, text, reason in coeng_ro:
        items.append({"id": fid, "text": text, "category": "COENG_RO", "reason": reason})

    # 9. COENG_MULTIPLE (Multiple subscripts)
    coeng_multiple = [
        ("coeng_mult_ngo_ko_ro", "ង្គ្រ", "Ngo + Coeng Ko + Coeng Ro"),
        ("coeng_mult_ngo_ka_ro", "ង្ក្រ", "Ngo + Coeng Ka + Coeng Ro"),
        ("coeng_mult_sa_ta_ro", "ស្ត្រ", "Sa + Coeng Ta + Coeng Ro"),
        ("coeng_mult_sa_pa_ro", "ស្ប្រ", "Sa + Coeng Ba + Coeng Ro"),
        ("coeng_mult_ka_mo_lo", "ក្ម្ល", "Ka + Coeng Mo + Coeng Lo"),
        ("coeng_mult_sa_ng_ka", "ស្ង្ក", "Sa + Coeng Ngo + Coeng Ka"),
    ]
    for fid, text, reason in coeng_multiple:
        items.append({"id": fid, "text": text, "category": "COENG_MULTIPLE", "reason": reason})

    # 10. REGISTER_SHIFTER (Muusikatoan & Triisap)
    shifters = [
        ("shifter_muusikatoan_ba", "ប៊", "Ba + Muusikatoan (U+17C9)"),
        ("shifter_triisap_sa", "ស៊", "Sa + Triisap (U+17CA)"),
        ("shifter_triisap_ha", "ហ៊", "Ha + Triisap"),
        ("shifter_triisap_ba", "ប៉", "Ba + Muusikatoan (Bap)"),
        ("shifter_muusikatoan_vowel_i", "ប៉ិ", "Ba + Muusikatoan + Vowel I (Shifter replaced by U / context)"),
        ("shifter_triisap_vowel_i", "ស៊ិ", "Sa + Triisap + Vowel I"),
        ("shifter_triisap_vowel_ii", "ស៊ី", "Sa + Triisap + Vowel II"),
        ("shifter_triisap_vowel_aa", "ស៊ា", "Sa + Triisap + Vowel AA"),
        ("shifter_muusikatoan_vowel_aa", "ប៉ា", "Ba + Muusikatoan + Vowel AA"),
    ]
    for fid, text, reason in shifters:
        items.append({"id": fid, "text": text, "category": "REGISTER_SHIFTER", "reason": reason})

    # 11. ROBAT (Robat sign)
    robat = [
        ("robat_ka", "ក៌", "Ka + Robat (U+17CC)"),
        ("robat_to", "ទ៌", "To + Robat"),
        ("robat_ba", "ប៌", "Ba + Robat"),
        ("robat_mo", "ម៌", "Mo + Robat"),
        ("robat_sa", "ស៌", "Sa + Robat"),
        ("robat_ha", "ហ៌", "Ha + Robat"),
        ("robat_ka_aa", "ក៌ា", "Ka + Robat + Vowel AA"),
        ("robat_ka_u", "ក៌ុ", "Ka + Robat + Vowel U"),
    ]
    for fid, text, reason in robat:
        items.append({"id": fid, "text": text, "category": "ROBAT", "reason": reason})

    # 12. ABOVE_MARK & BELOW_MARK (Diacritics and signs)
    marks = [
        ("sign_nikahit_ka", "កំ", "Ka + Nikahit (U+17C6)"),
        ("sign_reahmuk_ka", "កះ", "Ka + Reahmuk (U+17C7)"),
        ("sign_yuukaleapintu_ka", "កៈ", "Ka + Yuukaleapintu (U+17C8)"),
        ("sign_bantoc_ka", "ក់", "Ka + Bantoc (U+17CB)"),
        ("sign_toandakhiat_ka", "ក៍", "Ka + Toandakhiat (U+17CD)"),
        ("sign_kakabat_ka", "ក៎", "Ka + Kakabat (U+17CE)"),
        ("sign_ahsda_ka", "ក៏", "Ka + Ahsda (U+17CF)"),
        ("sign_samyok_ka", "ក័", "Ka + Samyok Sannya (U+17D0)"),
        ("sign_viriam_ka", "ក៑", "Ka + Viriam (U+17D1)"),
        ("sign_atthacan_ka", "ក៝", "Ka + Atthacan (U+17DD)"),
        ("sign_bathamasat_ka", "ក៓", "Ka + Bathamasat (U+17D3)"),
    ]
    for fid, text, reason in marks:
        items.append({"id": fid, "text": text, "category": "ABOVE_MARK", "reason": reason})

    # 13. MULTIPLE_MARKS (Combinations of marks and vowels)
    mult_marks = [
        ("mult_ka_aa_nikahit", "កាំ", "Ka + Vowel AA + Nikahit (Kam)"),
        ("mult_ka_u_nikahit", "កុំ", "Ka + Vowel U + Nikahit (Kum)"),
        ("mult_ka_om_reahmuk", "កុំះ", "Ka + Vowel U + Nikahit + Reahmuk"),
        ("mult_ka_coeng_mo_bantoc", "ក្មត់", "Ka + Coeng Mo + Bantoc"),
        ("mult_ka_coeng_ka_nikahit", "ក្កំ", "Ka + Coeng Ka + Nikahit"),
        ("mult_ka_i_toandakhiat", "កិ៍", "Ka + Vowel I + Toandakhiat (Ligature / vertical stacking)"),
    ]
    for fid, text, reason in mult_marks:
        items.append({"id": fid, "text": text, "category": "MULTIPLE_MARKS", "reason": reason})

    # 14. BROKEN_CLUSTER & INVALID_SEQUENCE
    broken = [
        ("broken_leading_coeng_ka", "\u17D2ក", "Broken cluster: Leading Coeng before Ka"),
        ("broken_isolated_coeng", "\u17D2", "Broken cluster: Isolated Coeng"),
        ("broken_isolated_vowel_aa", "\u17B6", "Broken cluster: Isolated Vowel AA"),
        ("broken_isolated_vowel_e", "\u17C1", "Broken cluster: Isolated Vowel E"),
        ("broken_isolated_sign_nikahit", "\u17C6", "Broken cluster: Isolated Nikahit"),
        ("broken_isolated_sign_toandakhiat", "\u17CD", "Broken cluster: Isolated Toandakhiat"),
        ("invalid_vowel_before_base", "\u17C1ក", "Invalid sequence: Pre-base vowel before base"),
        ("invalid_multiple_vowels", "កាិុ", "Invalid sequence: Multiple stacked vowels (AA + I + U)"),
        ("invalid_duplicate_shifters", "ក៉៉", "Invalid sequence: Duplicate Muusikatoan"),
        ("invalid_double_coeng", "ក្្ក", "Invalid sequence: Double Coeng (H + H + C)"),
        ("invalid_coeng_zwnj_coeng", "ក្\u200C្ក", "Invalid sequence: Coeng + ZWNJ + Coeng"),
        ("invalid_coeng_without_follower", "ក្", "Invalid sequence: Trailing Coeng"),
    ]
    for fid, text, reason in broken:
        items.append({"id": fid, "text": text, "category": "BROKEN_CLUSTER", "reason": reason})

    # 15. ZWJ_ZWNJ (Joiner controls)
    joiners = [
        ("joiner_coeng_zwj_ka", "ក្\u200Dក", "Coeng + ZWJ + Ka (Explicit subjoiner display)"),
        ("joiner_coeng_zwnj_ka", "ក្\u200Cក", "Coeng + ZWNJ + Ka (Prevent coeng formation)"),
        ("joiner_base_zwnj_vowel", "ក\u200Cេ", "Base + ZWNJ + Vowel E"),
        ("joiner_indep_vowel_zwj", "ឥ\u200Dក", "Independent vowel + ZWJ + Ka"),
    ]
    for fid, text, reason in joiners:
        items.append({"id": fid, "text": text, "category": "ZWJ_ZWNJ", "reason": reason})

    # 16. KHMER_DIGITS & PUNCTUATION
    digits_punct = [
        ("digits_all", "០១២៣៤៥៦៧៨៩", "Khmer digits 0-9"),
        ("symbols_divination", "៰៱៲៳៴៵៶៷៸៹", "Khmer divination lore symbols"),
        ("punct_khan", "។", "Khmer sign Khan (Sentence full stop)"),
        ("punct_bariyoosan", "៕", "Khmer sign Bariyoosan (Section / chapter end)"),
        ("punct_camnuc_pii", "៖", "Khmer sign Camnuc Pii Kuuh (Colon)"),
        ("punct_lek_too", "ៗ", "Khmer sign Lek Too (Repetition mark)"),
        ("punct_beyyal", "៘", "Khmer sign Beyyal (Et cetera)"),
        ("punct_phnaek_muan", "៙", "Khmer sign Phnaek Muan (Opening text sign)"),
        ("punct_koomuut", "៚", "Khmer sign Koomuut (Closing text sign)"),
        ("symbol_riel", "៛", "Khmer currency symbol Riel"),
        ("symbol_avakrah", "ៜ", "Khmer sign Avakrahasanya"),
    ]
    for fid, text, reason in digits_punct:
        cat = "KHMER_DIGITS" if "digit" in fid or "divination" in fid else "PUNCTUATION"
        items.append({"id": fid, "text": text, "category": cat, "reason": reason})

    # 17. REAL_WORD (Real Khmer vocabulary)
    real_words = [
        ("word_kampuchea", "កម្ពុជា", "Kingdom of Cambodia: Base Ka + Base Mo + Coeng Po + Vowel U + Base Co + Vowel AA"),
        ("word_khmer", "ខ្មែរ", "Khmer: Base Kha + Coeng Mo + Vowel AE + Base Ro"),
        ("word_sangkhream", "សង្គ្រាម", "War (Sangkhream): Complex multi-syllable with Coeng Ko + Coeng Ro + Vowel AA"),
        ("word_krasuong", "ក្រសួង", "Ministry: Coeng Ro + Base Ka + Base Sa + Vowel UA + Base Ngo"),
        ("word_srok", "ស្រុក", "District/Country: Base Sa + Coeng Ro + Vowel U + Base Ka"),
        ("word_preah", "ព្រះ", "Royal/Sacred (Preah): Base Po + Coeng Ro + Sign Reahmuk"),
        ("word_reachanachak", "រាជាណាចក្រ", "Kingdom (Reach-anachak): Multi-word compound"),
        ("word_orkun", "អរគុណ", "Thank you (Orkun)"),
        ("word_suasdei", "សួស្តី", "Hello (Suasdei): Base Sa + Vowel UA + Base Sa + Coeng Da + Vowel II"),
        ("word_pheasa_khmer", "ភាសាខ្មែរ", "Khmer Language"),
        ("word_chbab", "ច្បាប់", "Law (Chbab): Base Ca + Coeng Ba + Vowel AA + Base Ba + Sign Bantoc"),
        ("word_khnhom", "ខ្ញុំ", "I / Me (Khnhom): Base Kha + Coeng Nyo + Vowel U + Sign Nikahit"),
        ("word_sdeipi", "ស្តីពី", "Regarding (Sdei-pi)"),
        ("word_thngai", "ថ្ងៃ", "Day (Thngai)"),
        ("word_prik", "ព្រឹក", "Morning (Prik)"),
    ]
    for fid, text, reason in real_words:
        items.append({"id": fid, "text": text, "category": "REAL_WORD", "reason": reason})

    # 18. REAL_SENTENCE (Full real sentences)
    sentences = [
        ("sentence_motto", "ព្រះរាជាណាចក្រកម្ពុជា ជាតិ សាសនា ព្រះមហាក្សត្រ", "Cambodian National Motto: Kingdom, Nation, Religion, King"),
        ("sentence_greeting", "សូមស្វាគមន៍មកកាន់ព្រះរាជាណាចក្រកម្ពុជា។", "Welcome to the Kingdom of Cambodia."),
        ("sentence_constitution", "រដ្ឋធម្មនុញ្ញ នៃព្រះរាជាណាចក្រកម្ពុជា ជាច្បាប់កំពូលនៃប្រទេស។", "Constitution of the Kingdom of Cambodia is the supreme law."),
    ]
    for fid, text, reason in sentences:
        items.append({"id": fid, "text": text, "category": "REAL_SENTENCE", "reason": reason})

    # 19. MIXED_SCRIPT (Mixed script runs)
    mixed = [
        ("mixed_en_khmer", "Englishខ្មែរ", "English word followed directly by Khmer"),
        ("mixed_khmer_en", "ខ្មែរEnglish", "Khmer word followed directly by English"),
        ("mixed_currency", "$100ខ្មែរ", "Dollar sign + digits + Khmer"),
        ("mixed_email", "ខ្មែរ@example.com", "Khmer + Email address"),
        ("mixed_parens", "(ខ្មែរ)", "Khmer in ASCII parentheses"),
        ("mixed_date", "២០២៦-08-24", "Khmer digits + hyphen + ASCII digits"),
        ("mixed_spaced", "ភាសាខ្មែរ (Khmer Language) ២០២៦", "Khmer text with English in brackets and year"),
    ]
    for fid, text, reason in mixed:
        items.append({"id": fid, "text": text, "category": "MIXED_SCRIPT", "reason": reason})

    return items

def main():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    font_path = os.path.join(repo_root, "assets", "fonts", "Battambang-Regular.ttf")
    
    if not os.path.exists(font_path):
        font_path = "/Users/hengmengsroin/Library/Fonts/Battambang-Regular.ttf"
    
    with open(font_path, "rb") as f:
        font_data = f.read()
    
    face = hb.Face(font_data)
    font = hb.Font(face)
    
    hb_ver = get_hb_version()
    font_sha = hashlib.sha256(font_data).hexdigest()
    
    corpus = build_corpus()
    fixtures = []
    
    for item in corpus:
        text = item["text"]
        codepoints = [f"0x{ord(c):04X}" for c in text]
        
        # Determine script run shaping
        if item["category"] == "MIXED_SCRIPT":
            # For mixed script, we shape as Khmr if it's the primary segment or trace
            glyphs = shape_string(font, text, script="Khmr")
        else:
            glyphs = shape_string(font, text, script="Khmr")
            
        fixtures.append({
            "id": item["id"],
            "text": text,
            "codepoints": codepoints,
            "category": item["category"],
            "reason": item["reason"],
            "font": "Battambang-Regular",
            "harfbuzz": {
                "glyphs": glyphs
            }
        })
        
    output = {
        "oracle": {
            "harfbuzz_version": hb_ver,
            "font_sha256": font_sha,
            "font_name": "Battambang-Regular",
            "font_file": "Battambang-Regular.ttf",
            "units_per_em": 2048,
            "fixture_count": len(fixtures),
            "fixture_version": "1.0.0"
        },
        "fixtures": fixtures
    }
    
    fixtures_dir = os.path.join(repo_root, "test", "fixtures")
    os.makedirs(fixtures_dir, exist_ok=True)
    out_file = os.path.join(fixtures_dir, "khmer_golden_fixtures.json")
    
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
        
    print(f"Successfully generated {len(fixtures)} golden fixtures to {out_file}")
    print(f"HarfBuzz version: {hb_ver}")
    print(f"Font SHA256: {font_sha}")

if __name__ == "__main__":
    main()
