import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import MenuFramesRelay


class TestMenuFramesRelay(unittest.TestCase):
    def setUp(self):
        self.relay = MenuFramesRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

    def tearDown(self):
        del self.relay

    def extract_tag(self, xml: str, tag_name: str) -> Union[None, str]:
        xml_tree = bs4.BeautifulSoup(xml, "xml")
        tag = xml_tree.find(tag_name)
        return str(tag) if tag is not None else ''

    def test_dataset(self):
        self.assertTrue(self.relay.update_required)
        self.relay.notify_applied()
        self.assertFalse(self.relay.update_required)

    def test_remove_frame_button(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        mainframe_buttons = str(self.relay._soup.RelayFile.Frames.Buttons)

        self.assertNotEqual(mainframe_buttons, '<Buttons></Buttons>')
        self.relay.delete_button(frame_name='Hammer Main Menu', text_string='Button1')
        mainframe_buttons = str(self.relay._soup.RelayFile.Frames.Buttons).replace('\n','')
        self.assertEqual(mainframe_buttons, '<Buttons></Buttons>')

    def test_create_frame_button(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        mainframe_buttons = str(self.relay._soup.RelayFile.Frames.Buttons)
        mainframe_buttons = mainframe_buttons.replace('\n','')
        default_buttons = '<Buttons><record><Height>58</Height><Width>63</Width><ButtonLeft>324</ButtonLeft><ButtonTop>216</ButtonTop><ApplicationBinding>0</ApplicationBinding><BindingParameter>0</BindingParameter><TransparentColor>63519</TransparentColor><States><record><State>1</State><ActionListId>0</ActionListId><TextOnlyOnLocalGraphics>0</TextOnlyOnLocalGraphics><TemplateId>0</TemplateId><Color>24</Color><ButtonActions><record><ActionEvent>9930</ActionEvent><ActionSubEvent>1</ActionSubEvent><DelayType>0</DelayType><InitialDelay>0</InitialDelay><ResetDelay>0</ResetDelay><ObjectId>0</ObjectId><Parameter1>7777100</Parameter1><Parameter2>7</Parameter2><NextFrameId>0</NextFrameId><NavigationType>0</NavigationType><ActionCompleteListId>0</ActionCompleteListId></record></ButtonActions><ButtonTexts><record><TextTop>3</TextTop><TextLeft>0</TextLeft><TextWidth>63</TextWidth><TextHeight>58</TextHeight><Transparent>1</Transparent><Foreground>65535</Foreground><Background>0</Background><FontId>70000000880</FontId><TextString>Button1</TextString><ApplicationBinding>0</ApplicationBinding><BindingParameter>0</BindingParameter><JustificationType>2</JustificationType><ShadowFlag>1</ShadowFlag><WrapFlag>1</WrapFlag></record></ButtonTexts></record></States></record></Buttons>'
        self.assertEqual(default_buttons, mainframe_buttons)

        self.relay.create_button_record(frame_name="Hammer Main Menu", button_left=596, button_top=280)
        self.relay.create_button_state(frame_name="Hammer Main Menu", button_left=596, button_top=280)
        self.relay.create_button_action(frame_name="Hammer Main Menu", button_left=596, button_top=280)
        self.relay.create_button_text(frame_name="Hammer Main Menu", button_left=596, button_top=280, text_string="Button2")

        mainframe_buttons = str(self.relay._soup.RelayFile.Frames.Buttons)
        mainframe_buttons = mainframe_buttons.replace('\n', '')
        edited_buttons = '<Buttons><record><Height>58</Height><Width>63</Width><ButtonLeft>324</ButtonLeft><ButtonTop>216</ButtonTop><ApplicationBinding>0</ApplicationBinding><BindingParameter>0</BindingParameter><TransparentColor>63519</TransparentColor><States><record><State>1</State><ActionListId>0</ActionListId><TextOnlyOnLocalGraphics>0</TextOnlyOnLocalGraphics><TemplateId>0</TemplateId><Color>24</Color><ButtonActions><record><ActionEvent>9930</ActionEvent><ActionSubEvent>1</ActionSubEvent><DelayType>0</DelayType><InitialDelay>0</InitialDelay><ResetDelay>0</ResetDelay><ObjectId>0</ObjectId><Parameter1>7777100</Parameter1><Parameter2>7</Parameter2><NextFrameId>0</NextFrameId><NavigationType>0</NavigationType><ActionCompleteListId>0</ActionCompleteListId></record></ButtonActions><ButtonTexts><record><TextTop>3</TextTop><TextLeft>0</TextLeft><TextWidth>63</TextWidth><TextHeight>58</TextHeight><Transparent>1</Transparent><Foreground>65535</Foreground><Background>0</Background><FontId>70000000880</FontId><TextString>Button1</TextString><ApplicationBinding>0</ApplicationBinding><BindingParameter>0</BindingParameter><JustificationType>2</JustificationType><ShadowFlag>1</ShadowFlag><WrapFlag>1</WrapFlag></record></ButtonTexts></record></States></record><record><ButtonLeft>596</ButtonLeft><ButtonTop>280</ButtonTop><Width>63</Width><Height>58</Height><States><record><State>1</State><Color>2016</Color><ButtonActions><record><ActionEvent>10144</ActionEvent><ActionSubEvent>0</ActionSubEvent><NextFrameId>0</NextFrameId></record></ButtonActions><ButtonTexts><record><TextTop>3</TextTop><TextLeft>0</TextLeft><TextWidth>63</TextWidth><TextHeight>58</TextHeight><Transparent>1</Transparent><Foreground>65535</Foreground><FontId>70000000880</FontId><TextString>Button2</TextString><JustificationType>2</JustificationType><ShadowFlag>0</ShadowFlag><WrapFlag>1</WrapFlag></record></ButtonTexts></record></States></record></Buttons>'

        self.assertEqual(edited_buttons, mainframe_buttons)

        self.assertTrue(self.relay.update_required)


if __name__ == '__main__':
    unittest.main()
