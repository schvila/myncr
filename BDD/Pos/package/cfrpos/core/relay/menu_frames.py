__all__ = [
    "MenuFramesRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from .. bdd_utils.errors import ProductError
from . import RelayFile


@wrap_all_methods_with_log_trace
class MenuFramesRelay(RelayFile):
    """
    Representation of the MenuFrames relay file.
    """
    _pos_name = "MenuFrames"
    _filename = "MenuFrames.xml"
    _default_version = 20
    _sort_rules = [
        ("Frames", [
            ("FrameId", int)
        ])
    ]

    def create_frame_record(self, frame_name: str, frame_id: int, frame_left: int = 316, frame_top: int = 212,
                           width: int = 484, height: int = 263, color: int = 65504) -> None:
        """
        Create or modify a frame record.

        :param frame_name: Frame name.
        :param frame_id: Frame ID.
        :param frame_left: First frame coordinate.
        :param frame_top: Second frame coordinate.
        :param width: Frame width.
        :param height: Frame height.
        :param color: Color of the frame background.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("FrameName", frame_name)
            line("FrameId", frame_id)
            line("FrameLeft", frame_left)
            line("FrameTop", frame_top)
            line("Width", width)
            line("Height", height)
            line("Color", color)

        match_description = getattr(self._soup.RelayFile, 'Frames').find('FrameName', string=frame_name)
        if match_description is not None:
            parent = match_description.parent
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.Frames, doc)


    def create_button_record(self, frame_name: str, button_left: int, button_top: int, width: int = 63,
                            height: int = 58, states: str = ''):
        """
        Create a button record.

        :param frame_name: Frame name.
        :param button_left: First coordinate of the button on a frame.
        :param button_top: Second coordinate of the button on a frame.
        :param width: Width of the button.
        :param height: Height of the button.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ButtonLeft", button_left)
            line("ButtonTop", button_top)
            line("Width", width)
            line("Height", height)
            line("States", states)

        frame_id = self._find_frame_id(frame_name)
        match_frame_record = getattr(self._soup.RelayFile, 'Frames').find('FrameId', string=frame_id)
        match_button_record = match_frame_record.parent.find('Buttons')
        self._append_tag(match_button_record, doc)


    def create_button_state(self, frame_name: str, button_left: int, button_top: int, state: int = 1,
                           color: int = 2016, button_action: str = '', button_text: str = '') -> None:
        """
        Create a button state record.

        :param frame_name: Frame name.
        :param button_left: First coordinate of the button on a frame grid.
        :param button_top: Second coordinate of the button on a frame grid.
        :param state: Button state, default 1.
        :param color: Color of the button background, default 2016 = green.
        :param button_action: Button action record.
        :param button_text: Button text record.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("State", state)
            line("Color", color)
            line("ButtonActions", button_action)
            line("ButtonTexts", button_text)

        match_button_record = self.find_button_record(frame_name=frame_name, button_left=button_left, button_top=button_top)
        match_state = match_button_record.find('States')
        self._append_tag(match_state, doc)


    def create_button_action(self, frame_name: str, button_left: int, button_top: int, action_event: int = 10144,
                            action_sub_event: int =0, next_frame_id: int = 0) -> None:
        """
        Create or modifies a button action record.

        :param frame_name: Frame name.
        :param button_left: First coordinate of the button on a frame grid.
        :param button_top: Second coordinate of the button on a frame grid.
        :param action_event: Button action event, defines what will happen after button is pressed, 10144 set default as ACTION_EVENT_BACK.
        :param action_sub_event: Action sub event assigned to the button.
        :param next_frame_id: ID of the frame that will be displayed once the given button is pressed.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ActionEvent", action_event)
            line("ActionSubEvent", action_sub_event)
            line("NextFrameId", next_frame_id)

        match_button_record = self.find_button_record(frame_name=frame_name, button_left=button_left, button_top=button_top)
        match_state = match_button_record.find('States')
        match_action_record = match_state.find('ButtonActions')
        if len(match_action_record) > 0:
            match_action = match_action_record.find('ActionEvent', string=action_event)
            match_sub_action = match_action_record.find('ActionSubEvent', string=action_sub_event)
            if match_action is not None:
                if match_sub_action is not None:
                    parent = match_sub_action.parent
                    self._modify_tag(parent, doc)
                parent = match_action.parent
                self._modify_tag(parent, doc)
            else:
                self._append_tag(match_action_record, doc)
        else:
            self._append_tag(match_action_record, doc)


    def create_button_text(self, frame_name: str, button_left: int, button_top: int, text_string: str) -> None:
        """
        Create or modifies a button text record, defining the text that will be displayed on the button.

        :param frame_name: Frame name.
        :param button_left: First coordinate of the button on a frame grid.
        :param button_top: Second coordinate of the button on a frame grid.
        :param text_string: Name of the button.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("TextTop", 3)
            line("TextLeft", 0)
            line("TextWidth", 63)
            line("TextHeight", 58)
            line("Transparent", 1)
            line("Foreground", 65535)
            line("FontId", 70000000880)
            line("TextString", text_string)
            line("JustificationType", 2)
            line("ShadowFlag", 0)
            line("WrapFlag", 1)

        match_record = self.find_button_record(frame_name=frame_name, button_left=button_left, button_top=button_top)
        match_state = match_record.find('States')
        match_text_record = match_state.find('ButtonTexts')
        if len(match_text_record) > 0:
            match_text = match_text_record.find('TextString', string = text_string)
            if match_text is not None:
                parent = match_text.parent
                self._modify_tag(parent, doc)
            else:
                self._append_tag(match_text_record, doc)
        else:
            self._append_tag(match_text_record, doc)


    def find_button(self, frame_name: str, button_name: str) -> None:
        """
        Find a button with a provided name on the given frame.

        :param frame_name: Frame name.
        :param button_name: Name of the button to be checked.
        """
        frame_id = self._find_frame_id(frame_name)
        match_frame = getattr(self._soup.RelayFile, 'Frames').find('FrameId', string=frame_id).parent.find('Buttons')
        match_states = match_frame.find_all('States')
        match_button_name = None
        for record in match_states:
            match_button_texts = record.parent.find('ButtonTexts')
            if match_button_texts is not None and  match_button_texts.parent.find('TextString', string=button_name) is not None:
                match_button_name = match_button_texts.parent.find('TextString')
                break
        return match_button_name


    def find_button_record(self, frame_name: str, button_left: str, button_top: str):
        """
        Method to find if there is a button record created on a given position on the provided frame.

        :param frame_name: Frame name.
        :param button_left: First coordinate of the button on a frame grid.
        :param button_top: Second coordinate of the button on a frame grid.
        """
        frame_id = self._find_frame_id(frame_name)
        match_frame = getattr(self._soup.RelayFile, 'Frames').find('FrameId', string=frame_id)
        match_button_left = match_frame.parent.find('Buttons').find_all('ButtonLeft', string=button_left)
        for el in match_button_left:
            if el.parent.find('ButtonTop').string == str(button_top):
                return el.parent


    def delete_button(self, frame_name: str, text_string: str) -> None:
        """
        Method to delete a button from a frame.

        :param frame_name: Frame name.
        :param button_name: Name of the button to be deleted.
        """
        button_text_record = self.find_button(frame_name, text_string)
        if button_text_record is not None:
            button_record = button_text_record.parent.parent.parent.parent.parent
            self._remove_tag(button_record)
        else:
            raise ProductError("Given button [{}] does not exist on the frame [{}].".format(text_string, frame_name))


    def _find_frame_id(self, frame_name: str) -> int:
        """
        Find ID of the frame with provided name.

        :param frame_name: Frame name.
        """
        match_frame = getattr(self._soup.RelayFile, 'Frames').find('FrameName', string=frame_name)
        if match_frame is None:
            raise ProductError("Frame with given name [{}] does not exist.".format(frame_name))

        if frame_name == 'Hammer Main Menu':
            match_id = 70010000554
        else:
            match_id = getattr(self._soup.RelayFile, 'Frames').find('FrameName', string=frame_name).parent.find('FrameId').string

        return match_id