const {expect}=require('@playwright/test');

async function fillFlutterField(page,label,value) {
 const field=page.getByRole('textbox',{name:label,exact:true});
 await field.click();
 // Flutter swaps the semantic field for a native input after handling focus.
 // Typing immediately after the click can lose characters on a busy CI runner.
 const input=field.and(page.locator('input, textarea'));
 await expect(input).toBeFocused();
 await input.fill(value);
 await expect(input).toHaveValue(value);
}

module.exports={fillFlutterField};
