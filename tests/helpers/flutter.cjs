const {expect}=require('@playwright/test');

async function fillFlutterField(page,label,value) {
 const field=page.getByRole('textbox',{name:label,exact:true});
 await field.click();
 // Flutter swaps the semantic field for a native input after handling focus.
 // Typing immediately after the click can lose characters on a busy CI runner.
 const input=field.and(page.locator('input, textarea'));
 await expect(input).toBeFocused();
 // Send ordinary keyboard events so Flutter updates its editing controller.
 // DOM fill can be overwritten by a pending engine editing-state update.
 await input.press('ControlOrMeta+A');
 await input.pressSequentially(value,{delay:15});
 await expect(input).toHaveValue(value);
}

module.exports={fillFlutterField};
