from jinja2 import Template
from bs4 import BeautifulSoup as bs


TAG_JINJA_START = '{{'
TAG_JINJA_END = '}}'


class ReceiptComparer:
    def __init__(self, jinja: dict):
        self.jinja = jinja

    def compare_lines(self, line: str, printed_line: str, html: bool = True):

        start = line.find(TAG_JINJA_START)
        end = line.find(TAG_JINJA_END)
        if (start != -1) and (end != -1):
            if not html:
                print("Jinja tags are not supported in plaintext receipt validation, skipping line.")
                return True
            line = self.apply_jinja(line)

        if html:
            result = (line == printed_line)
        else:
            result = (line[1:-1] == printed_line)
        if not result:
            print("Printed line doesn't match the expected one.")
            print("  Printed: '{}'\n  Expected: '{}'".format(printed_line, line))
        return result

    def apply_jinja(self, text: str):
        template = Template(text)
        return template.render(**self.jinja)

    def convert_to_plain_text(self, orig_receipt: str) -> list:
        """
        Method to convert the html-like receipt output of the simulator into a plain text format. Jinja is not supported.
        The receipt is returned as a list of lines.
        """
        receipt = ''
        soup = bs(orig_receipt, 'lxml')
        for tag in soup.find('body').contents:
            if tag.name == 'br':
                receipt = receipt + '/n'
                continue
            elif tag.get_text() == ' ':
                receipt = receipt + ' '
                continue
            line = tag.get_text()
            segment_width, alignment = self._parse_all_tag_classes(tag)
            formatted_segment = self._format_segment(line, segment_width, alignment)
            receipt = receipt + formatted_segment
        return receipt.split('/n')

    def _format_segment(self, current_segment: str, segment_width: int = 40, alignment: str = 'left') -> str:
        """
        Helper method to translate the desired justification, segment width and the segment content into a formatted
        segment using whitespaces.
        :param current_segment: The segment content to be formatted.
        :param segment_width: Desired segment width.
        :param alignment: Desired segment content alignment.
        """
        spaces = segment_width - len(current_segment)
        if len(current_segment) > segment_width:
            current_segment = current_segment[:segment_width]
        if alignment == 'left':
            current_segment = current_segment + spaces * ' '
        elif alignment == 'center':
            current_segment = spaces // 2 * ' ' + current_segment + ((spaces // 2 + spaces % 2) * ' ')
        elif alignment == 'right':
            current_segment = spaces * ' ' + current_segment
        return current_segment

    def _parse_all_tag_classes(self, tag, default_alignment: str = 'left', default_segment_width: int = 40) -> [int, str]:
        """
        Helper method to parse the given tag's attributes for alignment and segment width.
        :param tag: Tag whose attributes should be parsed.
        :param default_alignment: Alignment to be used if not specified in the tag attributes. Only the following values
               are allowed 'left/center/right'. If anything else is supplied 'left' will be used.
        :param default_segment_width: Segment width to be used if not specified in the tag attributes.
               40 characters usually means the whole receipt line.
        """
        segment_width = default_segment_width
        alignment = default_alignment if default_alignment in ['left', 'center', 'right'] else 'left'
        for attr in tag.attrs['class']:
            if 'width-' in attr:
                segment_width = int(attr[6:])
                continue
            if attr == 'double-width' and segment_width < 21:
                segment_width = segment_width * 2
                continue
            if attr == 'center':
                alignment = 'center'
                continue
            elif attr == 'right':
                alignment = 'right'
                continue
            elif attr == 'left':
                alignment = 'left'
                continue
        return segment_width, alignment

    def compare_receipt_sizes(self, expected_receipt: list, printed_receipt: list) -> bool:
        if len(expected_receipt) != len(printed_receipt):
            print('Printed receipt:')
            for line in printed_receipt:
                print('"' + line + '"')
            print('The printed receipt has {} lines, expected {}."'.format(len(printed_receipt), len(expected_receipt)))
            match = False
        else:
            match = True
        return match


def compare_receipts(expected_receipt_table, printed_receipt: list, html: bool = True, **kwargs) -> bool:
    result = True
    rc = ReceiptComparer(kwargs)
    if not html:
        printed_receipt = rc.convert_to_plain_text('<br/>'.join(printed_receipt))
    if not rc.compare_receipt_sizes(expected_receipt_table.rows, printed_receipt):
        return False
    for expected, printed in zip(expected_receipt_table, printed_receipt):
        result &= rc.compare_lines(expected['line'], printed, html)
    return result
